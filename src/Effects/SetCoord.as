void Draw_Effect_SetBlockCoord() {

    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);

    UI::TextWrapped("This will set .BlockUnitCoord for all items based on their position.\nThis can help fix unselectable items.");

    if (UI::Button("Run set .BlockUnitCoord")) {
        auto map = editor.Challenge;
        for (uint i = 0; i < map.AnchoredObjects.Length; i++) {
            auto item = map.AnchoredObjects[i];
            item.BlockUnitCoord = PosToCoord(item.AbsolutePositionInMap);
        }
        Notify("Set .BlockUnitCoord on " + map.AnchoredObjects.Length + " items.");
    }
}
