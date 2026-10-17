# Analytics endpoint is intentionally explicit until quiz history persistence
# is connected. It must not return fabricated retention curves or scores.

walker:pub get_analytics {
    has subject_name: str;

    can compute_analytics with `Root entry {
        report {
            "status": "not_available",
            "error": "Analytics are unavailable until quiz history persistence is connected.",
            "subject": self.subject_name
        };
    }
}
