document.addEventListener("DOMContentLoaded", function () {
  fetch("${api_endpoint}/count")
    .then((response) => response.json())
    .then((data) => {
      document.getElementById("visitorCount").textContent = data.visitor_count;
    })
    .catch((error) => {
      console.error("Error fetching visitor count:", error);
      document.getElementById("visitorCount").textContent =
        "Error fetching visitor count";
    });
});
