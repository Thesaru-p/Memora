cl import from "@jac/mobui" { View, Text, TextInput, ScrollView, Pressable, StyleSheet }
cl import from .preview_image_picker { PreviewImagePicker }

sv import from main { get_dashboard, get_openrouter_status, ingest_lecture }

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
    "buttonText": {"fontSize": 16, "fontWeight": "600", "color": "#ffffff"},
    "modeRow": {"flexDirection": "row", "gap": 8, "marginTop": 2},
    "modePill": {"flex": 1, "padding": 12, "borderRadius": 12, "backgroundColor": "#f0f4f2", "borderWidth": 1, "borderColor": "#cfd9d4", "alignItems": "center"},
    "modePillActive": {"backgroundColor": "#008565", "borderColor": "#008565"},
    "modePillText": {"fontSize": 13, "fontWeight": "600", "color": "#475569"},
    "modePillTextActive": {"fontSize": 13, "fontWeight": "700", "color": "#ffffff"},
    "badge": {"paddingHorizontal": 10, "paddingVertical": 6, "borderRadius": 8, "backgroundColor": "#e7f5f0"},
    "badgeText": {"fontSize": 13, "fontWeight": "600", "color": "#006b52"}
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
        upload_status: str = "Choose slide photo(s) to test vision extraction.",
        upload_error: str = "",
        uploading: bool = False,
        ingestion_mode: str = "append",
        selected_slides: list = [],
        session_slides_count: int = 0;

    def image_selected(encoded: str, name: str, size: int, mime_type: str, all_items = None) -> None {
        upload_error = "";
        if not mime_type.startswith("image/") {
            upload_error = "Choose a JPG, PNG, or WebP image.";
            return;
        }
        if size > 5242880 {
            upload_error = "Image is larger than 5 MB. Choose a smaller photo.";
            return;
        }
        if not encoded {
            upload_error = "The browser could not read that image.";
            return;
        }

        if all_items and len(all_items) > 1 {
            selected_slides = all_items;
            image_b64 = "data:" + mime_type + ";base64," + encoded;
            image_name = name;
            upload_status = str(len(all_items)) + " slides selected and ready to ingest.";
        } else {
            image_b64 = "data:" + mime_type + ";base64," + encoded;
            image_name = name;
            selected_slides = [{
                "encoded": encoded,
                "name": name,
                "size": size,
                "mime_type": mime_type
            }];
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
        if len(selected_slides) == 0 and not image_b64 {
            upload_error = "Choose slide photo(s) first.";
            return;
        }

        uploading = True;
        is_replace_initial = (ingestion_mode == "replace");

        try {
            total_items = len(selected_slides) if len(selected_slides) > 0 else 1;
            last_concepts_count = 0;
            processed_count = 0;

            if len(selected_slides) > 1 {
                idx = 0;
                for slide in selected_slides {
                    curr_name = str(slide["name"]);
                    curr_b64 = "data:" + str(slide["mime_type"]) + ";base64," + str(slide["encoded"]);
                    upload_status = "Extracting concepts from slide " + str(idx + 1) + " of " + str(total_items) + " (" + curr_name + ")…";

                    slide_replace = is_replace_initial if idx == 0 else False;
                    slide_notes = upload_notes if idx == 0 else "";

                    result = root spawn ingest_lecture(
                        subject_name=upload_subject,
                        lecture_title=upload_title,
                        notes_text=slide_notes,
                        image_b64=curr_b64,
                        replace_existing=slide_replace
                    );

                    if result.reports and len(result.reports) > 0 {
                        data = result.reports[len(result.reports) - 1];
                        if str(data["status"]) == "success" {
                            last_concepts_count = int(data["total_concepts"]);
                            processed_count += 1;
                        } else {
                            upload_error = "Slide " + curr_name + " failed: " + str(data["error"]);
                            break;
                        }
                    } else {
                        upload_error = "No result returned for slide " + curr_name;
                        break;
                    }
                    idx += 1;
                }
            } else {
                curr_b64 = image_b64 if image_b64 else ("data:" + str(selected_slides[0]["mime_type"]) + ";base64," + str(selected_slides[0]["encoded"]));
                upload_status = "Extracting concepts with OpenRouter…";
                result = root spawn ingest_lecture(
                    subject_name=upload_subject,
                    lecture_title=upload_title,
                    notes_text=upload_notes,
                    image_b64=curr_b64,
                    replace_existing=is_replace_initial
                );
                if result.reports and len(result.reports) > 0 {
                    data = result.reports[len(result.reports) - 1];
                    if str(data["status"]) == "success" {
                        last_concepts_count = int(data["total_concepts"]);
                        processed_count = 1;
                    } else {
                        upload_error = str(data["error"]);
                        upload_status = "Extraction failed.";
                    }
                } else {
                    upload_error = "The ingestion endpoint returned no result.";
                }
            }

            if not upload_error and processed_count > 0 {
                session_slides_count += processed_count;
                mode_label = "replaced lecture · " if is_replace_initial else "accumulated · ";
                upload_status = "Success · " + str(processed_count) + " slide(s) processed (" + mode_label + str(last_concepts_count) + " total concepts in lecture)";
                image_b64 = "";
                selected_slides = [];
                if is_replace_initial {
                    ingestion_mode = "append";
                }
                load_overview();
            }
        } except Exception {
            upload_error = "Could not upload the images. Check the preview output and retry.";
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
            sub_name = upload_subject if upload_subject.strip() else "Computer Networks";
            result = root spawn get_dashboard(subject_name=sub_name);
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

    append_style = styles.modePillActive if ingestion_mode == "append" else styles.modePill;
    append_text_style = styles.modePillTextActive if ingestion_mode == "append" else styles.modePillText;
    replace_style = styles.modePillActive if ingestion_mode == "replace" else styles.modePill;
    replace_text_style = styles.modePillTextActive if ingestion_mode == "replace" else styles.modePillText;
    has_queued_slides = len(selected_slides) > 1;
    has_session_slides = session_slides_count > 0;

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
            <Text style={styles.title}>Upload lecture slide(s)</Text>
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

            <View style={{"gap": 6}}>
                <Text style={styles.label}>UPLOAD MODE OPTION</Text>
                <View style={styles.modeRow}>
                    <Pressable
                        accessibilityRole="button"
                        onPress={lambda { ingestion_mode = "append"; }}
                        style={append_style}
                    >
                        <Text style={append_text_style}>➕ Append slides</Text>
                    </Pressable>
                    <Pressable
                        accessibilityRole="button"
                        onPress={lambda { ingestion_mode = "replace"; }}
                        style={replace_style}
                    >
                        <Text style={replace_text_style}>🔄 Replace lecture</Text>
                    </Pressable>
                </View>
                {ingestion_mode == "append" and <Text style={styles.note}>
                    Append mode: Multiple slides accumulate new concepts into this lecture without losing prior review history.
                </Text>}
                {ingestion_mode == "replace" and <Text style={styles.note}>
                    Replace mode: Clears previous lecture concepts and starts fresh with newly extracted concepts.
                </Text>}
            </View>

            <PreviewImagePicker onSelected={image_selected} />

            {has_queued_slides and <View style={styles.badge}>
                <Text style={styles.badgeText}>
                    {"📁 " + str(len(selected_slides)) + " slides queued for batch ingestion"}
                </Text>
            </View>}

            {has_session_slides and <Text style={styles.label}>
                {"Slides uploaded this session: " + str(session_slides_count)}
            </Text>}

            <Text accessibilityLiveRegion="polite" style={styles.error if upload_error != "" else styles.note}>
                {upload_error if upload_error != "" else upload_status}
            </Text>
            <Pressable accessibilityRole="button" disabled={uploading} onPress={upload_lecture_image} style={styles.button}>
                <Text style={styles.buttonText}>
                    {"Uploading…" if uploading else "Extract image concepts"}
                </Text>
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
