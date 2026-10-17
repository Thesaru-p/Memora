def:pub app() -> JsxElement {
    has subject: str = "maai";
    has message: str = "The JacHammer preview is ready.";

    return <main style={{"maxWidth": "900px", "margin": "0 auto", "padding": "40px", "fontFamily": "system-ui"}}>
        <h1>Memora</h1>
        <p>{message}</p>
        <label>Subject</label>
        <input value={subject} />
        <button onClick={lambda -> None { message = "Use the Expo app or API walkers to continue testing."; }}>
            Test Memora
        </button>
    </main>;
}
