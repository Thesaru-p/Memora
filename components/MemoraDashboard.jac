import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.badge { Badge }

sv import from ..main { get_dashboard }

def:pub MemoraDashboard() -> JsxElement {
    has retention_text: str = "—",
        concepts_text: str = "—",
        topic_text: str = "Loading",
        due_text: str = "Checking your schedule",
        streak_text: str = "—",
        retention_width: str = "0%",
        loading: bool = True,
        error_message: str = "";

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

    can with entry { load_overview(); }

    return <main className="dashboard-page">
        <div className="dashboard-wrap">
            <header className="dashboard-header">
                <div className="dashboard-brand">
                    <div className="dashboard-mark">M</div>
                    <div><p className="dashboard-eyebrow">Memora · Learning dashboard</p><h1 className="dashboard-heading">Computer Networks</h1></div>
                </div>
                <Badge variant="secondary">CS-301</Badge>
            </header>
            <section className="dashboard-stats">
                <Card className="dashboard-card">
                    <CardHeader className="dashboard-card-head">
                        <div><CardDescription className="dashboard-label">Retention health</CardDescription><CardTitle className="dashboard-value">{retention_text}</CardTitle></div>
                        <div className="dashboard-chip">R</div>
                    </CardHeader>
                    <CardContent>
                        <div className="dashboard-progress"><div className="dashboard-progress-fill" style={{"width": retention_width}} /></div>
                        <p className="dashboard-note">Keep concepts fresh with a short review.</p>
                    </CardContent>
                </Card>
                <Card className="dashboard-card">
                    <CardHeader className="dashboard-card-head">
                        <div><CardDescription className="dashboard-label">Concepts in rotation</CardDescription><CardTitle className="dashboard-value">{concepts_text}</CardTitle></div>
                        <div className="dashboard-chip">C</div>
                    </CardHeader>
                    <CardContent><p className="dashboard-note">Topics tracked for your next review.</p></CardContent>
                </Card>
                <Card className="dashboard-card">
                    <CardHeader className="dashboard-card-head">
                        <div><CardDescription className="dashboard-label">Next review</CardDescription><CardTitle className="dashboard-value dashboard-topic">{topic_text}</CardTitle></div>
                        <div className="dashboard-chip">N</div>
                    </CardHeader>
                    <CardContent><p className="dashboard-note">{due_text}</p></CardContent>
                </Card>
            </section>
            <Card className="dashboard-card">
                <CardHeader>
                    <CardTitle className="dashboard-lower-title">Your learning rhythm</CardTitle>
                    <CardDescription className="dashboard-lower-description">A little active recall helps strengthen what you learned.</CardDescription>
                </CardHeader>
                <CardContent>
                    {loading and <p className="dashboard-note">Loading your learning overview…</p>}
                    {not loading and error_message != "" and <p className="dashboard-error">{error_message} Refresh the page to try again.</p>}
                    {not loading and error_message == "" and <div className="dashboard-streak">
                        <div><p className="dashboard-label">Study streak</p><p className="dashboard-note">Small reviews build lasting recall.</p></div>
                        <p className="dashboard-streak-value">{streak_text} <span className="dashboard-streak-unit">days</span></p>
                    </div>}
                </CardContent>
            </Card>
        </div>
    </main>;
}
