import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { DashboardSquare01Icon, Analytics01Icon, Clock01Icon, CheckmarkCircle02Icon }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.badge { Badge }
import from .ui.progress { Progress }

sv import from ..main { get_dashboard }

def:pub MemoraDashboard() -> JsxElement {
    has retention_text: str = "—",
        concepts_text: str = "—",
        topic_text: str = "Loading",
        due_text: str = "Checking your schedule",
        streak_text: str = "—",
        loading: bool = True,
        error_message: str = "";

    async def load_overview() {
        loading = True;
        error_message = "";
        try {
            result = root spawn get_dashboard(subject_name="Computer Networks");
            if result.reports and len(result.reports) > 0 {
                data = result.reports[0];
                retention_text = str(data["overall_retention_pct"]) + "%";
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

    return <main className="min-h-screen bg-muted/40 px-4 py-8 sm:px-8">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-8">
            <header className="flex flex-wrap items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                    <div className="flex size-11 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm"><HugeiconsIcon icon={DashboardSquare01Icon} strokeWidth={2} className="size-5" /></div>
                    <div><p className="text-sm font-medium text-muted-foreground">Memora · Learning dashboard</p><h1 className="text-2xl font-semibold tracking-tight">Computer Networks</h1></div>
                </div>
                <Badge variant="secondary">CS-301</Badge>
            </header>
            <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <Card className="shadow-sm">
                    <CardHeader className="flex flex-row items-start justify-between gap-4">
                        <div><CardDescription>Retention health</CardDescription><CardTitle className="mt-2 text-3xl tabular-nums">{retention_text}</CardTitle></div>
                        <div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={Analytics01Icon} strokeWidth={2} className="size-4" /></div>
                    </CardHeader>
                    <CardContent><Progress value={0} /><p className="mt-3 text-sm text-muted-foreground">Keep concepts fresh with a short review.</p></CardContent>
                </Card>
                <Card className="shadow-sm">
                    <CardHeader className="flex flex-row items-start justify-between gap-4">
                        <div><CardDescription>Concepts in rotation</CardDescription><CardTitle className="mt-2 text-3xl tabular-nums">{concepts_text}</CardTitle></div>
                        <div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={CheckmarkCircle02Icon} strokeWidth={2} className="size-4" /></div>
                    </CardHeader>
                    <CardContent><p className="text-sm text-muted-foreground">Topics tracked for your next review.</p></CardContent>
                </Card>
                <Card className="shadow-sm sm:col-span-2 lg:col-span-1">
                    <CardHeader className="flex flex-row items-start justify-between gap-4">
                        <div><CardDescription>Next review</CardDescription><CardTitle className="mt-2 text-xl">{topic_text}</CardTitle></div>
                        <div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-4" /></div>
                    </CardHeader>
                    <CardContent><p className="text-sm text-muted-foreground">{due_text}</p></CardContent>
                </Card>
            </section>
            <Card className="shadow-sm">
                <CardHeader><CardTitle>Your learning rhythm</CardTitle><CardDescription>A little active recall helps strengthen what you learned.</CardDescription></CardHeader>
                <CardContent>
                    {loading and <p className="py-6 text-sm text-muted-foreground">Loading your learning overview…</p>}
                    {not loading and error_message != "" and <p className="py-6 text-sm text-destructive">{error_message} Refresh the page to try again.</p>}
                    {not loading and error_message == "" and <div className="flex flex-wrap items-center justify-between gap-4 rounded-xl border bg-background p-5">
                        <div><p className="font-medium">Study streak</p><p className="text-sm text-muted-foreground">Small reviews build lasting recall.</p></div>
                        <p className="text-3xl font-semibold tabular-nums">{streak_text} <span className="text-base font-normal text-muted-foreground">days</span></p>
                    </div>}
                </CardContent>
            </Card>
        </div>
    </main>;
}
