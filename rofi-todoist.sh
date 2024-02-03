#!/bin/bash
source env.sh

function notify(){
	local message=$1
	local icon=$2
	dunstify "Rofi Todoist" "$message" -i "$icon"
}

function addTask(){
  taskContent=$(rofi -dmenu -p "Enter Task")

  if [ -z "$taskContent" ]; then
    echo "No task entered. Exiting."
    exit 1
  fi

	if curl "https://api.todoist.com/rest/v2/tasks" \
			-X POST \
			--data "{\"content\": \"$taskContent\", \"project_id\": \"$TODOIST_INBOX_ID\"}" \
			-H "Content-Type: application/json" \
			-H "X-Request-Id: $(uuidgen)" \
			-H "Authorization: Bearer $TODOIST_API_KEY"; then
			notify "Task successfully added." 'task/addtask'
	else
			notify "Failed to add task." 'error'
	fi
}
function mainMenu {
    action=`printf "Add task\nComplete Task(soon)\nModify task(soon)\nExit" | rofi -dmenu -i -l 2 -p 'rofi-todoist'`
    if [ "$action" = "Add task" ]; then
        addTask
		elif [ "$action" = "Complete Task" ]; then
				echo 'soon'
		elif [ "$action" = "Modify task" ]; then
				echo 'soon'
    fi

}

mainMenu