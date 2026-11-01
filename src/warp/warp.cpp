#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopManager.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopTimer.hpp>
#include <hyprland/src/debug/HyprCtl.hpp>
#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <fstream>
#include <map>
#include <set>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <sstream>

namespace {
using Clock = std::chrono::steady_clock;
using Geo = Desktop::View::IGeometric;
HANDLE handle;
GLuint program = 0, vao = 0, vbo = 0;
bool shaderFailed = false;
uint64_t launches = 0, frames = 0, failures = 0;
constexpr int DURATION_MS = 560;
constexpr int MESH_ROWS = 96;
CHyprSignalListener openListener, focusListener;
uint64_t reusedMatches=0, focusedMatches=0;
SP<SHyprCtlCommand> ctl;
SP<CEventLoopTimer> timer;

struct Origin {
    std::string monitor;
    Vector2D pos, size;
    std::set<pid_t> pids;
    std::set<uintptr_t> windows;
    Clock::time_point armed = Clock::now();
    Clock::time_point ready = armed;
};
std::map<std::string, Origin> pending;
class Warp;
struct Running {
    PHLWINDOWREF window;
    Warp* transformer;
    Clock::time_point since;
};
std::vector<Running> running;

const char* vertex = R"(#version 300 es
layout(location=0) in vec2 position;
uniform vec2 resolution;
uniform vec4 rectangle;
uniform vec4 origin;
uniform float progress;
out vec2 sourceUV;
void main(){
    // The leading edge unfurls first. The neck stays on the island while
    // the lower rows travel out, then the upper rows catch up and flatten.
    float delay=.46*pow(1.-position.y,1.2);
    float phase=clamp((progress-delay)/(1.-delay),0.,1.);
    phase=phase*phase*(3.-2.*phase);
    vec2 source=rectangle.xy+position*rectangle.zw;
    vec2 start=origin.xy+position*origin.zw;
    vec2 destination=mix(start,source,phase);
    gl_Position=vec4(destination/resolution*2.-1.,0.,1.);
    sourceUV=source/resolution;
}
)";
const char* fragment = R"(#version 300 es
precision highp float;
uniform sampler2D image;
in vec2 sourceUV;
out vec4 color;
void main(){color=texture(image,sourceUV);}
)";

GLuint compile(GLenum type, const char* text) {
    const GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &text, nullptr);
    glCompileShader(shader);
    GLint ok = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (!ok) { glDeleteShader(shader); return 0; }
    return shader;
}

bool shaderReady() {
    if (program) return true;
    if (shaderFailed) return false;
    const auto vs = compile(GL_VERTEX_SHADER, vertex), fs = compile(GL_FRAGMENT_SHADER, fragment);
    if (!vs || !fs) {
        if (vs) glDeleteShader(vs);
        if (fs) glDeleteShader(fs);
        shaderFailed = true; failures++; return false;
    }
    const auto candidate = glCreateProgram();
    glAttachShader(candidate, vs); glAttachShader(candidate, fs); glLinkProgram(candidate);
    glDeleteShader(vs); glDeleteShader(fs);
    GLint ok = 0; glGetProgramiv(candidate, GL_LINK_STATUS, &ok);
    if (!ok) { glDeleteProgram(candidate); shaderFailed = true; failures++; return false; }
    program = candidate;
    glGenVertexArrays(1, &vao); glGenBuffers(1, &vbo);
    return true;
}

// The compositor owns the GL context. Restore every state touched by this pass.
struct GLState {
    GLint shader, array, buffer, active, texture, viewport[4];
    GLboolean blend, scissor, stencil, depth, mask[4];
    GLfloat clear[4];
    GLState() {
        glGetIntegerv(GL_CURRENT_PROGRAM,&shader); glGetIntegerv(GL_VERTEX_ARRAY_BINDING,&array);
        glGetIntegerv(GL_ARRAY_BUFFER_BINDING,&buffer); glGetIntegerv(GL_ACTIVE_TEXTURE,&active);
        glActiveTexture(GL_TEXTURE0); glGetIntegerv(GL_TEXTURE_BINDING_2D,&texture);
        glGetIntegerv(GL_VIEWPORT,viewport); glGetFloatv(GL_COLOR_CLEAR_VALUE,clear);
        glGetBooleanv(GL_COLOR_WRITEMASK,mask);
        blend=glIsEnabled(GL_BLEND); scissor=glIsEnabled(GL_SCISSOR_TEST);
        stencil=glIsEnabled(GL_STENCIL_TEST); depth=glIsEnabled(GL_DEPTH_TEST);
    }
    ~GLState() {
        glUseProgram(shader); glBindVertexArray(array); glBindBuffer(GL_ARRAY_BUFFER,buffer);
        glActiveTexture(GL_TEXTURE0); glBindTexture(GL_TEXTURE_2D,texture); glActiveTexture(active);
        glViewport(viewport[0],viewport[1],viewport[2],viewport[3]);
        glClearColor(clear[0],clear[1],clear[2],clear[3]); glColorMask(mask[0],mask[1],mask[2],mask[3]);
        for (const auto& [cap,on] : {std::pair<GLenum,GLboolean>{GL_BLEND,blend},{GL_SCISSOR_TEST,scissor},{GL_STENCIL_TEST,stencil},{GL_DEPTH_TEST,depth}})
            if (on) glEnable(cap); else glDisable(cap);
    }
};

class Warp final : public Render::IWindowTransformer {
  public:
    PHLWINDOWREF window;
    CBox origin;
    Clock::time_point since=Clock::now();
    bool started=false;
    bool reverse=false;
    std::array<SP<Render::IFramebuffer>,2> outputs;
    unsigned passIndex=0;
    void preWindowRender(CSurfacePassElement::SRenderData* data) override {
        passIndex=0;
        const auto w=window.lock();
        if(!w || !data)return;
        const auto current=w->position(Geo::GEOMETRIC_CURRENT),goal=w->position(Geo::GEOMETRIC_GOAL);
        const auto size=w->size(Geo::GEOMETRIC_GOAL);
        data->pos+=goal-current;data->w=size.x;data->h=size.y;
        w->positionAnimation()->setValueAndWarp(goal);
        w->sizeAnimation()->setValueAndWarp(size);
        if(!started){since=std::max(since,Clock::now());started=true;}
    }
    bool finished()const{return !reverse && started && Clock::now()-since>std::chrono::milliseconds(DURATION_MS+40);}
    Warp(PHLWINDOW w, const CBox& anchor, Clock::time_point notBefore, bool backwards=false) : window(w), origin(anchor), since(std::max(Clock::now(),notBefore)), reverse(backwards) {}

    void amendTransformedRenderData(const CBox&, SMotionBlurData* data) override {
        const auto monitor=g_pHyprRenderer->m_renderData.pMonitor;
        if (!monitor || !data) return;
        // Declare full-output coverage so the unfurl is not clipped to the
        // final window bounds. Equal boxes and one sample composite identically.
        data->enabled=true;data->previous={0,0,monitor->m_size.x,monitor->m_size.y};
        data->current=data->previous;data->samples=1;
    }

    SP<Render::IFramebuffer> transform(SP<Render::IFramebuffer> input) override {
        const auto w=window.lock();
        const auto monitor=g_pHyprRenderer->m_renderData.pMonitor;
        if (!w || !monitor || w->m_monitor.lock()!=monitor || !input || !input->getTexture()) return input;
        const float elapsed=std::clamp(std::chrono::duration<float,std::milli>(Clock::now()-since).count()/DURATION_MS,0.F,1.F);
        const float p=reverse?1.F-elapsed:elapsed;
        if (p>=1.F) return input;
        GLState state;
        if (!shaderReady()) return input;
        auto& output=outputs[(passIndex++)%outputs.size()];
        if (!output) output=g_pHyprRenderer->createFB("aether-warp");
        if (output->m_size!=input->m_size || !output->isAllocated()) {
            if (!output->alloc(input->m_size.x,input->m_size.y,input->m_drmFormat)) { failures++; return input; }
            output->setImageDescription(input->imageDescription());
        }
        auto binding=g_pHyprRenderer->bindTempFB(output);
        glDisable(GL_BLEND); glDisable(GL_SCISSOR_TEST); glDisable(GL_STENCIL_TEST); glDisable(GL_DEPTH_TEST);
        glColorMask(GL_TRUE,GL_TRUE,GL_TRUE,GL_TRUE);
        glViewport(0,0,input->m_size.x,input->m_size.y);
        glClearColor(0,0,0,0); glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(program); glBindVertexArray(vao); glBindBuffer(GL_ARRAY_BUFFER,vbo);
        std::vector<float> points;
        points.reserve(MESH_ROWS*12);
        for(int row=0;row<MESH_ROWS;row++){
            const float a=float(row)/MESH_ROWS,b=float(row+1)/MESH_ROWS;
            for(float n:{0.F,a,1.F,a,0.F,b,0.F,b,1.F,a,1.F,b}) points.push_back(n);
        }
        glBufferData(GL_ARRAY_BUFFER,points.size()*sizeof(float),points.data(),GL_STREAM_DRAW);
        glEnableVertexAttribArray(0); glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,nullptr);
        glActiveTexture(GL_TEXTURE0); glBindTexture(GL_TEXTURE_2D,input->getTexture()->m_texID);
        glUniform1i(glGetUniformLocation(program,"image"),0);
        glUniform2f(glGetUniformLocation(program,"resolution"),input->m_size.x,input->m_size.y);
        auto rect=w->getFullWindowBoundingBox().translate(-monitor->m_position).scale(monitor->m_scale);
        glUniform4f(glGetUniformLocation(program,"rectangle"),rect.x,rect.y,rect.w,rect.h);
        auto anchor=origin.copy().scale(monitor->m_scale);
        glUniform4f(glGetUniformLocation(program,"origin"),anchor.x,anchor.y,anchor.w,anchor.h);
        glUniform1f(glGetUniformLocation(program,"progress"),p);
        glDrawArrays(GL_TRIANGLES,0,MESH_ROWS*6); frames++;
        return output;
    }
};

std::string tokenFor(PHLWINDOW window) {
    // Read only this marker; never log or retain the rest of the application environment.
    std::ifstream file("/proc/"+std::to_string(window->getPID())+"/environ",std::ios::binary);
    std::string entry;
    size_t bytes=0;
    while (std::getline(file,entry,'\0') && (bytes+=entry.size()+1)<262144)
        if (entry.starts_with("AETHER_WARP_TOKEN=")) return entry.substr(18);
    return {};
}

void tick() {
    for (auto it=running.begin();it!=running.end();) {
        const auto w=it->window.lock();
        const auto elapsed=Clock::now()-it->since;
        if (!w || !w->m_isMapped || (elapsed>std::chrono::milliseconds(2000) || it->transformer->finished())) {
            if (w) {
                std::erase_if(w->m_transformers,[ptr=it->transformer](const auto& t){return t.get()==ptr;});
                if (auto m=w->m_monitor.lock()) g_pHyprRenderer->damageMonitor(m);
            }
            it=running.erase(it);
        } else {
            if (auto m=w->m_monitor.lock()) g_pHyprRenderer->damageMonitor(m);
            ++it;
        }
    }
    timer->updateTimeout(running.empty()?std::nullopt:std::optional<Time::steady_dur>{std::chrono::milliseconds(8)});
}

bool startWarp(PHLWINDOW w, const Origin& origin, bool reverse=false) {
    if (!w || !w->m_isMapped || running.size()>=3 || !w->positionAnimation()->enabled()) return false;
    if (std::ranges::any_of(running,[&](const auto& entry){return entry.window.lock()==w;})) return false;
    const auto monitor=w->m_monitor.lock();
    if (!monitor || monitor->m_name!=origin.monitor || w->m_X11DoesntWantBorders) return false;
    const auto target=w->size(Geo::GEOMETRIC_GOAL), pos=w->position(Geo::GEOMETRIC_GOAL);
    if (target.x<80 || target.y<80) return false;
    Animation::SViewAnimationContext ctx;
    ctx.pos={pos,pos};ctx.size={target,target};ctx.alpha={1.F,1.F};
    auto transform=makeUnique<Warp>(w,CBox{origin.pos,origin.size},origin.ready,reverse);
    auto* ptr=transform.get();
    w->m_transformers.push_back(std::move(transform));
    w->m_animationController.apply(ctx);
    running.push_back({w,ptr,Clock::now()});launches++;
    timer->updateTimeout(std::chrono::milliseconds(1));
    return true;
}

void prune(){std::erase_if(pending,[](const auto& pair){return Clock::now()-pair.second.armed>std::chrono::seconds(12);});}

void onOpen(PHLWINDOW w) {
    if (!w || pending.empty()) return;
    prune();
    auto found=pending.find(tokenFor(w));
    bool reused=false;
    if (found==pending.end()) {
        for (auto it=pending.begin();it!=pending.end();++it) {
            if (Clock::now()-it->second.armed>std::chrono::seconds(4) || !it->second.pids.contains(w->getPID())) continue;
            if (found==pending.end() || it->second.armed>found->second.armed) found=it;
        }
        reused=found!=pending.end();
    }
    if (found==pending.end()) return;
    const auto origin=found->second;pending.erase(found);
    if (startWarp(w,origin) && reused) reusedMatches++;
}

void onFocus(PHLWINDOW w) {
    if (!w || pending.empty()) return;
    prune();
    auto found=pending.end();
    for (auto it=pending.begin();it!=pending.end();++it) {
        if (Clock::now()-it->second.armed>std::chrono::seconds(4) || !it->second.windows.contains(reinterpret_cast<uintptr_t>(w.get()))) continue;
        if (found==pending.end() || it->second.armed>found->second.armed) found=it;
    }
    if (found==pending.end()) return;
    const auto origin=found->second;pending.erase(found);
    if(startWarp(w,origin)) focusedMatches++;
}

std::string command(eHyprCtlOutputFormat, std::string request) {
    std::istringstream input(request);
    std::string word,action; input>>word;
    if (word=="aetherwarp") input>>action; else action=word;
    prune();
    if(action=="fold" || action=="unfold" || action=="cancel") {
        std::string address;input>>address;
        PHLWINDOW target;
        for(const auto& w:Desktop::windowState()->windows())
            if(std::format("0x{:x}",reinterpret_cast<uintptr_t>(w.get()))==address){target=w;break;}
        if(!target || !target->m_isMapped)return "error: window no longer exists";
        if(action=="cancel") {
            for(auto it=running.begin();it!=running.end();) {
                if(it->window.lock()!=target){++it;continue;}
                std::erase_if(target->m_transformers,[ptr=it->transformer](const auto& t){return t.get()==ptr;});
                it=running.erase(it);
            }
            if(auto m=target->m_monitor.lock())g_pHyprRenderer->damageMonitor(m);
            return "ok";
        }
        Origin origin;
        input>>origin.monitor>>origin.pos.x>>origin.pos.y>>origin.size.x>>origin.size.y;
        if(!input || !std::isfinite(origin.pos.x) || !std::isfinite(origin.pos.y) || !std::isfinite(origin.size.x) || !std::isfinite(origin.size.y) ||
            std::abs(origin.pos.x)>20000 || std::abs(origin.pos.y)>20000 || origin.size.x<10 || origin.size.x>1000 || origin.size.y<4 || origin.size.y>200)
            return "error: invalid fold origin";
        int delay=0;if(input>>delay){if(delay<0 || delay>1000)return "error: invalid fold delay";}
        origin.ready=origin.armed+std::chrono::milliseconds(delay);
        return startWarp(target,origin,action=="fold")?"ok":"error: window cannot animate";
    }
    if (action=="settle") {
        std::string token;input>>token;auto found=pending.find(token);
        if(found==pending.end())return "ok";
        const auto w=Desktop::focusState()->window();
        if(w && found->second.windows.contains(reinterpret_cast<uintptr_t>(w.get()))) {
            const auto origin=found->second;pending.erase(found);
            if(startWarp(w,origin))focusedMatches++;
        }
        return "ok";
    }
    if (action=="status" || action.empty())
        return std::format(R"({{"version":"1.0","style":"lamp","durationMs":560,"anchorFix":true,"islandHandoff":true,"foldSupport":true,"reusedMatches":{},"focusedMatches":{},"pending":{},"active":{},"launches":{},"frames":{},"shaderFailed":{},"failures":{}}})",reusedMatches,focusedMatches,pending.size(),running.size(),launches,frames,shaderFailed?"true":"false",failures);
    if (action=="arm") {
        std::string token; Origin origin;
        input>>token>>origin.monitor>>origin.pos.x>>origin.pos.y>>origin.size.x>>origin.size.y;
        if (!input || token.size()!=32 || token.find_first_not_of("0123456789abcdef")!=std::string::npos || origin.monitor.size()>100 ||
            !std::isfinite(origin.pos.x) || !std::isfinite(origin.pos.y) || !std::isfinite(origin.size.x) || !std::isfinite(origin.size.y) ||
            origin.size.x<10 || origin.size.x>1000 || origin.size.y<4 || origin.size.y>200 || std::abs(origin.pos.x)>20000 || std::abs(origin.pos.y)>20000)
            return "error: invalid launch origin";
        unsigned count=0;
        if(input>>count){
            if(count>32)return "error: too many target processes";
            for(unsigned i=0;i<count;i++){pid_t pid=0;if(!(input>>pid) || pid<=0)return "error: invalid target process";origin.pids.insert(pid);}
        }
        int delay=0;if(input>>delay){if(delay<0 || delay>1000)return "error: invalid launch delay";origin.ready=origin.armed+std::chrono::milliseconds(delay);}
        for(const auto& w:Desktop::windowState()->windows())if(origin.pids.contains(w->getPID()))origin.windows.insert(reinterpret_cast<uintptr_t>(w.get()));
        if (pending.size()>=16) return "error: too many pending launches";
        pending[token]=origin;
        return "ok";
    }
    return "error: unknown action";
}
}

APICALL EXPORT std::string PLUGIN_API_VERSION(){return HYPRLAND_API_VERSION;}
APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE h) {
    handle=h;
    if (HyprlandAPI::getHyprlandVersion(h).hash!=GIT_COMMIT_HASH) throw std::runtime_error("Aether Warp: rebuild for this Hyprland version");
    timer=makeShared<CEventLoopTimer>(std::nullopt,[](SP<CEventLoopTimer>,void*){tick();},nullptr);
    g_pEventLoopManager->addTimer(timer);
    ctl=HyprlandAPI::registerHyprCtlCommand(h,{.name="aetherwarp",.exact=false,.fn=command});
    if (!ctl) throw std::runtime_error("Aether Warp: control registration failed");
    openListener=Event::bus()->m_events.window.openLate.listen([](PHLWINDOW w){onOpen(w);});
    focusListener=Event::bus()->m_events.window.active.listen([](PHLWINDOW w,Desktop::eFocusReason){onFocus(w);});
    return {"Aether Warp","Synchronized island-edge window handoff","Aether","1.5"};
}
APICALL EXPORT void PLUGIN_EXIT() {
    openListener.reset();focusListener.reset();
    if (timer) {timer->cancel();g_pEventLoopManager->removeTimer(timer);timer.reset();}
    for (auto& r:running) if (auto w=r.window.lock()) {
        std::erase_if(w->m_transformers,[ptr=r.transformer](const auto& t){return t.get()==ptr;});
        if (auto m=w->m_monitor.lock()) g_pHyprRenderer->damageMonitor(m);
    }
    running.clear();pending.clear();
    if (program) {Render::GL::g_pHyprOpenGL->makeEGLCurrent();glDeleteProgram(program);glDeleteVertexArrays(1,&vao);glDeleteBuffers(1,&vbo);program=vao=vbo=0;}
}
