bool UserHasPermissions = false;

void Main() {
    UserHasPermissions = Permissions::OpenAdvancedMapEditor();
    if (!UserHasPermissions) {
        NotifyWarning("This plugin requires the advanced map editor");
        return;
    }
    CheckAndSetGameVersionSafe();
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
    if (!GameVersionSafe) return;
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    auto currPg = cast<CSmArenaClient>(GetApp().CurrentPlayground);
    IsInCurrentPlayground = currPg !is null;

    EnteringEditor = !IsInEditor;
    // we're in the editor if it's not null and we were in the editor, or if we weren't then we wait for the editor to be ready for a request
    IsInEditor = editor !is null && (
        IsInEditor || (
            editor.PluginMapType !is null
            && editor.PluginMapType.IsEditorReadyForRequest
        )
    );
    EnteringEditor = EnteringEditor && IsInEditor;
}

void Render() {
    if (!GameVersionSafe) return;
    if (!UserHasPermissions) return;
    if (EnteringEditor)
        trace('Updating editor watchers.');
    // send null if we're not flagged as in the editor to wait for it to update
    UpdateEditorWatchers(IsInEditor ? cast<CGameCtnEditorFree>(GetApp().Editor) : null);
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
    if (!GameVersionSafe) return;
    if (!UserHasPermissions) return;
    if (UI::MenuItem(MenuTitle, "", ShowWindow)) {
        ShowWindow = !ShowWindow;
    }
}

/** Render function called every frame.
*/
void RenderInterface() {
    if (!GameVersionSafe) return;
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


uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    return memberTy.Offset;
}


void SetClipboard(const string &in msg) {
    IO::SetClipboard(msg);
    Notify("Copied: " + msg);
}

bool ClickableLabel(const string &in label, const string &in value, const string &in between = ": ") {
    UI::Text(label + between + value);
    return UI::IsItemClicked();
}

void CopiableLabeledValue(const string &in label, const string &in value) {
    if (ClickableLabel(label, value)) {
        SetClipboard(value);
    }
}
