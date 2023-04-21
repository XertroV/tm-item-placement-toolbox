bool UserHasPermissions = false;

void Main() {
    UserHasPermissions = Permissions::OpenAdvancedMapEditor();
    if (!UserHasPermissions) {
        NotifyWarning("This plugin requires the advanced map editor");
    } else {
        // nothing to do
    }
}


void OnDisabled() { Unload(); }
void OnDestroyed() { Unload(); }
void Unload() {
// #if DEPENDENCY_MLHOOK
//     MLHook::UnregisterMLHooksAndRemoveInjectedML();
// #endif
}


bool IsInEditor = false;
bool IsInCurrentPlayground = false;
bool EnteringEditor = false;

void RenderEarly() {
    if (!UserHasPermissions) return;
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    auto currPg = cast<CSmArenaClient>(GetApp().CurrentPlayground);
    IsInCurrentPlayground = currPg !is null;

    EnteringEditor = !IsInEditor;
    IsInEditor = editor !is null;
    EnteringEditor = EnteringEditor && IsInEditor;

    if (EnteringEditor)
        trace('Updating editor watchers.');
    UpdateEditorWatchers(editor);
    if (EnteringEditor)
        trace('Done updating editor watchers.');
}


void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

const string PluginIcon = Icons::Wrench;
const string MenuTitle = "\\$3f3" + PluginIcon + "\\$z " + Meta::ExecutingPlugin().Name;

/** Render function called every frame intended only for menu items in `UI`. */
void RenderMenu() {
    if (!UserHasPermissions) return;
    if (UI::MenuItem(MenuTitle, "", ShowWindow)) {
        ShowWindow = !ShowWindow;
    }
}

/** Render function called every frame.
*/
void RenderInterface() {
    if (!UserHasPermissions) return;
    if (!ShowWindow || !IsInEditor || IsInCurrentPlayground) return;
    vec2 size = vec2(600, 800);
    vec2 pos = (vec2(Draw::GetWidth(), Draw::GetHeight()) - size) / 2.;
    UI::SetNextWindowSize(int(size.x), int(size.y), UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(int(pos.x), int(pos.y), UI::Cond::FirstUseEver);
    UI::PushStyleColor(UI::Col::FrameBg, vec4(.2, .2, .2, .5));
    if (UI::Begin(MenuTitle, ShowWindow, UI::WindowFlags::None)) {
        DrawMainWindowInner();
    }
    UI::End();
    UI::PopStyleColor();
}





void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::SetNextWindowSize(400, 0, UI::Cond::Always);
        UI::BeginTooltip();
        UI::TextWrapped(msg);
        UI::EndTooltip();
    }
}
