const express = require('express');
const app = express();

app.get('/', (req, res) => res.send("Hello! This is a new Express app."));

app.listen(4000, () => console.log("Server running on port 4000"));
