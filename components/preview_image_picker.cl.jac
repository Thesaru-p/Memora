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

        files_len: int = int(files.length);
        reader_type: any = (window as any).FileReader;
        loaded_items: list[any] = [];

        def read_next(idx: int) -> None {
            if idx >= files_len {
                if len(loaded_items) > 0 {
                    first = loaded_items[0];
                    onSelected(first["encoded"], first["name"], first["size"], first["mime_type"], loaded_items);
                }
                return;
            }
            f: any = files[idx];
            if not str(f.type).startswith("image/") or f.size > 5242880 {
                read_next(idx + 1);
                return;
            }
            reader: BrowserFileReader = new(reader_type as type[BrowserFileReader]);
            reader.onload = lambda (load_event: any) -> None {
                data_url = str(load_event.target.result);
                encoded = data_url.split(",")[1] if "," in data_url else "";
                loaded_items.append({
                    "encoded": encoded,
                    "name": str(f.name),
                    "size": int(f.size),
                    "mime_type": str(f.type)
                });
                read_next(idx + 1);
            };
            reader.readAsDataURL(f);
        }

        read_next(0);
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
        Choose slide photo(s)
        <input
            type="file"
            multiple={True}
            accept="image/jpeg,image/png,image/webp"
            onChange={choose_file}
            style={{"display": "none"}}
        />
    </label>;
}
