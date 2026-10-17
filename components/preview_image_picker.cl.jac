obj BrowserFileReader {
    has onload: any = None;
    def readAsDataURL(file: any) -> None { }
}

def:pub PreviewImagePicker(onSelected: any) -> JsxElement {
    def choose_file(event: ChangeEvent) -> None {
        input = event.target as HTMLInputElement;
        files: any = input.files;
        if not files or files.length == 0 {
            return;
        }
        file: any = files[0];
        if not str(file.type).startswith("image/") or file.size > 5242880 {
            onSelected("", str(file.name), int(file.size), str(file.type));
            return;
        }

        reader_type: any = (window as any).FileReader;
        reader: BrowserFileReader = new(reader_type as type[BrowserFileReader]);
        reader.onload = lambda (load_event: any) -> None {
            data_url = str(load_event.target.result);
            encoded = data_url.split(",")[1] if "," in data_url else "";
            onSelected(encoded, str(file.name), int(file.size), str(file.type));
        };
        reader.readAsDataURL(file);
    }

    return <label style={{
        "display": "block",
        "padding": "14px",
        "borderRadius": "14px",
        "backgroundColor": "#e7f5f0",
        "color": "#006b52",
        "fontWeight": 600,
        "textAlign": "center",
        "cursor": "pointer"
    }}>
        Choose slide photo
        <input
            type="file"
            accept="image/jpeg,image/png,image/webp"
            onChange={choose_file}
            style={{"display": "none"}}
        />
    </label>;
}
