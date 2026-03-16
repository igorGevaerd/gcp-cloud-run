import app from "./app";

const port = parseInt(process.env.PORT || "8080");

app.listen(port, () => {
  console.log(
    JSON.stringify({
      severity: "INFO",
      message: `Server listening on port ${port}`,
    }),
  );
});
