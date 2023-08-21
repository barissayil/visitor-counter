variable "unique_id" {
  description = "Unique ID for naming the bucket"
  type        = string
}

variable "index_source" {
  description = "Path to index.html source"
  type        = string
}

variable "css_source" {
  description = "Path to styles.css source"
  type        = string
}

variable "script_content" {
  description = "Rendered content for script.js"
  type        = string
}
