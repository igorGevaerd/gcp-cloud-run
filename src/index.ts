import app from "./app";

const port = parseInt(process.env.PORT || "8080");

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
