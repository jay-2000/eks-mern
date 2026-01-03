// const Task = require("../models/task");
// const express = require("express");
// const router = express.Router();

// router.post("/tasks", async (req, res) => {
//     try {
//         const task = await new Task(req.body).save();
//         res.send(task);
//     } catch (error) {
//         res.send(error);
//     }
// });

// router.get("/", async (req, res) => {
//     try {
//         const tasks = await Task.find();
//         res.send(tasks);
//     } catch (error) {
//         res.send(error);
//     }
// });

// router.put("/:id", async (req, res) => {
//     try {
//         const task = await Task.findOneAndUpdate(
//             { _id: req.params.id },
//             req.body
//         );
//         res.send(task);
//     } catch (error) {
//         res.send(error);
//     }
// });

// router.delete("/:id", async (req, res) => {
//     try {
//         const task = await Task.findByIdAndDelete(req.params.id);
//         res.send(task);
//     } catch (error) {
//         res.send(error);
//     }
// });

// module.exports = router;
const router = require("express").Router();
const Task = require("../models/task");

// GET all tasks
router.get("/", async (req, res) => {
    const tasks = await Task.find();
    res.send(tasks);
});

// ADD task
router.post("/", async (req, res) => {
    const task = new Task({ task: req.body.task });
    await task.save();
    res.send(task);
});

// UPDATE task
router.put("/:id", async (req, res) => {
    const task = await Task.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true }
    );
    res.send(task);
});

// DELETE task
router.delete("/:id", async (req, res) => {
    await Task.findByIdAndDelete(req.params.id);
    res.send({ success: true });
});

module.exports = router;
