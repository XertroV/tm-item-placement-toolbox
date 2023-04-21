#if DEPENDENCY_MLHOOK

uint count = 0;

class EditorExecHook : MLHook::HookMLEventsByType {
    EditorExecHook() {
        super("Editor_Angelscript_Cb");
    }

    void OnEvent(MLHook::PendingEvent@ event) override {
        // don't need the event, just want to run at ML time
        if (count < 10) {
            CheckItemsNodPool();
        }
        count++;
    }
}

#endif


void CheckItemsNodPool() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    trace('Nb PluginMapType.Items: ' + editor.PluginMapType.Items.Length);
    auto pmt = cast<CSmEditorPluginMapType>(editor.PluginMapType);
    trace('Nb pmt.Items: ' + pmt.Items.Length);
    auto editorTy = Reflection::GetType("CGameCtnEditorFree");
    auto pmtMember = editorTy.GetMember("PluginMapType");
    auto pmtTy = Reflection::GetType("CSmEditorPluginMapType");
    auto itemsMember = pmtTy.GetMember("Items");
    if (itemsMember.Offset < 0xffff) {
        auto pmtPointer = Dev::GetOffsetUint64(editor, pmtMember.Offset);
        auto nodPoolPtr = pmtPointer + itemsMember.Offset;
        trace('pmtPointer: ' + pmtPointer);
        trace('nodPoolPtr: ' + nodPoolPtr);
        IO::SetClipboard('' + nodPoolPtr);
        auto np2 = nodPoolPtr + 0x20;
        auto count = Dev::ReadUInt32(nodPoolPtr + 0x2c);
        trace('count: ' + count);
        auto nodPool = Dev::GetOffsetNod(pmt, itemsMember.Offset + 0x20);
        auto nod1 = Dev::GetOffsetNod(nodPool, 0x0);
        auto nodPtr = Dev::GetOffsetUint64(nodPool, 0x0);
        trace('nodPtr: ' + nodPtr);
        if (nod1 !is null) {
            auto nodTy = Reflection::TypeOf(nod1);
            if (nodTy !is null)
                trace('nod is of type; ' + nodTy.Name);
        }
        trace('if no type, nod type wasn\'t available');
    }
}


/**
 * in main:


#if DEPENDENCY_MLHOOK
    // MLHook::RegisterMLHook(EditorExecHook(), "Editor_Angelscript_Cb");
#endif
    startnew(CheckItemsNodPool);


 */
