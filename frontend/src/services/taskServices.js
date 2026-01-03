import axios from "axios";

const API = "/api/tasks";

export function getTasks() {
    return axios.get(API);
}

export function addTask(task) {
    return axios.post(API, task);
}

export function updateTask(id, task) {
    return axios.put(`${API}/${id}`, task);
}

export function deleteTask(id) {
    return axios.delete(`${API}/${id}`);
}
