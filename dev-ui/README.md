# Memora Dev UI

Temporary, dependency-free browser harness for testing Jac walker endpoints while the production mobile UI is under development.

## JacHammer

1. Start or ship `main.jac` with `OPENROUTER_API_KEY` configured as a secret.
2. Open `dev-ui/index.html` in the IDE preview.
3. Enter the deployed Jac API origin in **Jac API base URL** if the preview is hosted on a different origin.
4. Test text-only ingestion, image ingestion, dashboard data, and graph data.

If the preview and API have different origins, the Jac deployment must allow the preview origin through CORS.

## Local preview

Run the Jac API in one terminal:

```powershell
jac start main.jac
```

Serve this directory in another terminal:

```powershell
py -m http.server 5173 --directory dev-ui
```

Open `http://localhost:5173`, then set the API base URL to `http://localhost:8000`.
