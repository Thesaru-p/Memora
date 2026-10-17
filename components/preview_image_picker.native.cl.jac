cl import from "@jac/mobui" { View, Text }

# shortcut: the temporary JacHammer test picker is browser-only; replace with Dev 1's native picker.
def:pub PreviewImagePicker(onSelected: any) -> JsxElement {
    return <View style={{"padding": 14, "borderRadius": 14, "backgroundColor": "#e7f5f0"}}>
        <Text style={{"color": "#006b52", "textAlign": "center", "fontWeight": "600"}}>
            Image selection is available in the JacHammer preview.
        </Text>
    </View>;
}
