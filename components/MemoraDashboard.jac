cl import from "@jac/mobui" { View, Text, TextInput, ScrollView, Pressable, StyleSheet }
cl import from .preview_image_picker { PreviewImagePicker }

sv import from ..main { get_dashboard, get_openrouter_status, ingest_lecture }

cl glob styles = StyleSheet.create({
    "screen": {"flex": 1, "backgroundColor": "#f4f6f5"},
    "content": {"padding": 24, "paddingTop": 48, "paddingBottom": 40, "gap": 20, "width": "100%", "maxWidth": 480, "alignSelf": "center"},
    "header": {"flexDirection": "row", "alignItems": "center", "gap": 12},
    "mark": {"width": 48, "height": 48, "borderRadius": 16, "backgroundColor": "#008565", "alignItems": "center", "justifyContent": "center"},
    "markText": {"fontSize": 24, "fontWeight": "700", "color": "#ffffff"},
    "heading": {"fontSize": 26, "fontWeight": "700", "color": "#14251f"},
    "label": {"fontSize": 14, "color": "#65756e"},
    "card": {"padding": 22, "borderRadius": 20, "backgroundColor": "#ffffff", "borderWidth": 1, "borderColor": "#e2e8e4", "gap": 12},
    "value": {"fontSize": 40, "fontWeight": "700", "color": "#14251f"},
    "title": {"fontSize": 22, "fontWeight": "700", "color": "#14251f"},
    "note": {"fontSize": 15, "lineHeight": 23, "color": "#65756e"},
    "track": {"height": 8, "backgroundColor": "#e4ece8", "borderRadius": 4, "overflow": "hidden"},
    "fill": {"height": 8, "backgroundColor": "#0c9f75", "borderRadius": 4},
    "error": {"fontSize": 15, "color": "#b42318"},
    "input": {"padding": 14, "borderRadius": 12, "borderWidth": 1, "borderColor": "#cfd9d4", "backgroundColor": "#ffffff", "color": "#14251f", "fontSize": 15},
    "textArea": {"height": 100, "textAlignVertical": "top"},
    "button": {"padding": 16, "borderRadius": 14, "backgroundColor": "#008565", "alignItems": "center"},
    "buttonText": {"fontSize": 16, "fontWeight": "600", "color": "#ffffff"}
});

cl def:pub MemoraDashboard() -> JsxElement {
    has retention_text: str = "—",
        concepts_text: str = "—",
        topic_text: str = "Loading",
        due_text: str = "Checking your schedule",
        streak_text: str = "—",
        retention_width: str = "0%",
        loading: bool = True,
        error_message: str = "";
    has ai_status: str = "Checking configuration…",
        ai_message: str = "Reading the running backend configuration.",
        ai_model: str = "",
        ai_color: str = "#65756e",
        ai_checking: bool = False;
    has upload_subject: str = "Science",
        upload_title: str = "",
        upload_notes: str = "",
        image_b64: str = "",
        image_name: str = "",
        upload_status: str = "Choose a slide photo to test vision extraction.",
        upload_error: str = "",
        uploading: bool = False;

    def image_selected(encoded: str, name: str, size: int, mime_type: str) -> None {
        image_b64 = "";
        image_name = "";
        upload_error = "";
        if not mime_type.startswith("image/") {
            upload_error = "Choose a JPG, PNG, or WebP image.";
        } elif size > 5242880 {
            upload_error = "Image is larger than 5 MB. Choose a smaller photo.";
        } elif not encoded {
            upload_error = "The browser could not read that image.";
        } else {
            image_b64 = "data:" + mime_type + ";base64," + encoded;
            image_name = name;
            upload_status = name + " is ready to upload.";
        }
    }

    async def upload_lecture_image() {
        upload_error = "";
        if not upload_subject.strip() {
            upload_error = "Enter a subject name.";
            return;
        }
        if not upload_title.strip() {
            upload_error = "Enter a lecture title.";
            return;
        }
        if not image_b64 {
            upload_error = "Choose an image first.";
            return;
        }

        uploading = True;
        upload_status = "Extracting concepts with OpenRouter…";
        try {
            result = root spawn ingest_lecture(
                subject_name=upload_subject,
                lecture_title=upload_title,
                notes_text=upload_notes,
                image_b64=image_b64
            );
            if result.reports and len(result.reports) > 0 {
                data = result.reports[len(result.reports) - 1];
                if str(data["status"]) == "success" {
                    upload_status = "Success · " + str(data["total_concepts"]) + " concepts extracted from " + image_name;
                    image_b64 = "";
                } else {
                    upload_error = str(data["error"]);
                    upload_status = "Extraction failed.";
                }
            } else {
                upload_error = "The ingestion endpoint returned no result.";
            }
        } except Exception {
            upload_error = "Could not upload the image. Check the preview output and retry.";
        }
        uploading = False;
    }

    async def load_ai_status(verify: bool) {
        ai_checking = True;
        ai_color = "#65756e";
        ai_status = "Testing connection…" if verify else "Checking configuration…";
        try {
            result = root spawn get_openrouter_status(verify=verify);
            if result.reports and len(result.reports) > 0 {
                data = result.reports[0];
                status = str(data["status"]);
                ai_model = str(data["model"]);
                ai_message = str(data["message"]);
                ai_status = status.replace("_", " ");
                ai_color = "#b42318";
                if status == "connected" {
                    ai_status = "Connection verified";
                    ai_color = "#008565";
                } elif status == "configured" {
                    ai_status = "Key loaded · not tested";
                    ai_color = "#946200";
                } elif status == "reasoning_only" {
                    ai_status = "No final model answer";
                    ai_color = "#946200";
                } elif status == "missing_key" {
                    ai_status = "Key missing in backend";
                }
            } else {
                ai_status = "Status unavailable";
                ai_message = "The backend did not return a connection status.";
                ai_color = "#b42318";
            }
        } except Exception {
            ai_status = "Status unavailable";
            ai_message = "Could not reach the status endpoint. Retry after rebuilding the preview.";
            ai_color = "#b42318";
        }
        ai_checking = False;
    }

    async def load_overview() {
        loading = True;
        error_message = "";
        try {
            result = root spawn get_dashboard(subject_name="Computer Networks");
            if result.reports and len(result.reports) > 0 {
                data = result.reports[0];
                retention = data["overall_retention_pct"] as float;
                retention_text = str(retention) + "%";
                retention_width = str(retention) + "%";
                concepts_text = str(data["active_concepts_count"]);
                topic_text = str(data["next_quiz_topic"]);
                due_text = "Due in " + str(data["next_quiz_due_in_hours"]) + " hours";
                streak_text = str(data["study_streak_days"]);
            } else {
                error_message = "Dashboard data was unavailable.";
            }
        } except Exception {
            error_message = "Could not load your learning overview.";
        }
        loading = False;
    }

    can with entry {
        load_overview();
        load_ai_status(False);
    }

    return <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
        <View style={styles.header}>
            <View style={styles.mark}><Text style={styles.markText}>M</Text></View>
            <View style={{"flex": 1, "gap": 4}}>
                <Text style={styles.label}>Memora · CS-301</Text>
                <Text style={styles.heading}>Computer Networks</Text>
            </View>
        </View>
        <View style={styles.card}>
            <Text style={styles.label}>OpenRouter · Lecture AI</Text>
            <View accessibilityLiveRegion="polite" style={{"flexDirection": "row", "alignItems": "center", "gap": 8}}>
                <View style={{"width": 10, "height": 10, "borderRadius": 5, "backgroundColor": ai_color}} />
                <Text style={[styles.title, {"color": ai_color, "flex": 1}]}>{ai_status}</Text>
            </View>
            <Text style={styles.note}>{ai_message}</Text>
            {ai_model != "" and <Text style={styles.label}>{ai_model}</Text>}
            <Pressable accessibilityRole="button" disabled={ai_checking} onPress={lambda { load_ai_status(True); }} style={styles.button}>
                <Text style={styles.buttonText}>{"Checking…" if ai_checking else "Test OpenRouter"}</Text>
            </Pressable>
        </View>
        <View style={styles.card}>
            <Text style={styles.label}>Vision ingestion test</Text>
            <Text style={styles.title}>Upload a lecture image</Text>
            <TextInput
                accessibilityLabel="Subject name"
                placeholder="Subject"
                value={upload_subject}
                onChangeText={lambda (value: str) { upload_subject = value; }}
                style={styles.input}
            />
            <TextInput
                accessibilityLabel="Lecture title"
                placeholder="Lecture title"
                value={upload_title}
                onChangeText={lambda (value: str) { upload_title = value; }}
                style={styles.input}
            />
            <TextInput
                accessibilityLabel="Optional lecture notes"
                placeholder="Optional notes or context"
                value={upload_notes}
                onChangeText={lambda (value: str) { upload_notes = value; }}
                multiline={True}
                style={[styles.input, styles.textArea]}
            />
            <PreviewImagePicker onSelected={image_selected} />
            <Text accessibilityLiveRegion="polite" style={styles.error if upload_error != "" else styles.note}>
                {upload_error if upload_error != "" else upload_status}
            </Text>
            <Pressable accessibilityRole="button" disabled={uploading} onPress={upload_lecture_image} style={styles.button}>
                <Text style={styles.buttonText}>{"Uploading…" if uploading else "Extract image concepts"}</Text>
            </Pressable>
        </View>
        <View style={styles.card}>
            <Text style={styles.label}>Retention health</Text>
            <Text style={styles.value}>{retention_text}</Text>
            <View style={styles.track}><View style={[styles.fill, {"width": retention_width}]} /></View>
            <Text style={styles.note}>Keep concepts fresh with a short review.</Text>
        </View>
        <View style={styles.card}>
            <Text style={styles.label}>Concepts in rotation</Text>
            <Text style={styles.value}>{concepts_text}</Text>
            <Text style={styles.note}>Topics tracked for your next review.</Text>
        </View>
        <View style={styles.card}>
            <Text style={styles.label}>Next review</Text>
            <Text style={styles.title}>{topic_text}</Text>
            <Text style={styles.note}>{due_text}</Text>
        </View>
        <View style={styles.card}>
            <Text style={styles.title}>Your learning rhythm</Text>
            {loading and <Text style={styles.note}>Loading your learning overview…</Text>}
            {not loading and error_message != "" and <Text style={styles.error}>{error_message}</Text>}
            {not loading and error_message == "" and <View style={{"gap": 8}}>
                <Text style={styles.label}>Study streak</Text>
                <Text style={styles.value}>{streak_text} days</Text>
                <Text style={styles.note}>Small reviews build lasting recall.</Text>
            </View>}
        </View>
        <Pressable accessibilityRole="button" disabled={loading} onPress={load_overview} style={styles.button}>
            <Text style={styles.buttonText}>{"Refreshing…" if loading else "Refresh overview"}</Text>
        </Pressable>
    </ScrollView>;
}
