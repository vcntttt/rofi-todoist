#!/bin/bash
source env.sh
TODOIST_PROJECT_ID=$TODOIST_INBOX_ID

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

   priority=1

   if [[ $taskContent =~ ^p[1-4]\  ]]; then
       priority=${taskContent:1:1}
       taskContent=${taskContent:3}
   fi

   data="{\"content\": \"$taskContent\", \"project_id\": \"$TODOIST_PROJECT_ID\", \"priority\": $priority}"

	if curl "https://api.todoist.com/rest/v2/tasks" \
		-X POST \
		--data "$data" \
		-H "Content-Type: application/json" \
		-H "X-Request-Id: $(uuidgen)" \
		-H "Authorization: Bearer $TODOIST_API_KEY"; then
		notify "Task successfully added." 'tasks/addtask'
	else
			notify "Failed to add task." 'error'
	fi
}

function getTasks(){
    curl -X GET "https://api.todoist.com/rest/v2/tasks?project_id=$TODOIST_PROJECT_ID" \
         -H "Authorization: Bearer $TODOIST_API_KEY" | jq -r '.[] | "\(.id) \(.content)"'
}

function viewTasks(){
    local tasks=$(getTasks)
    local selectedTask=$(echo "$tasks" | rofi -dmenu -p "Select Task")
    local taskId=$(echo $selectedTask | awk '{print $1}')

    if [ -n "$taskId" ]; then
        actionsMenu "$taskId"
    else
        notify "No task selected." 'error'
    fi
}

function actionsMenu() {
    local action=$(printf "Complete\nModify\nReturn" | rofi -dmenu -p "Select an action for $taskId")
    local taskId=$1

    case $action in
        "Complete")
            completeTask $taskId
           ;;
        "Modify")
            modifyMenu $taskId
            ;;
        "Return")
            mainMenu
            ;;
        *)
            notify "No action selected or invalid option." 'error'
            ;;
    esac 
}

function completeTask(){
    local taskId=$1
    if curl -X POST "https://api.todoist.com/rest/v2/tasks/$taskId/close" \
    -H "Authorization: Bearer $TODOIST_API_KEY"; then
        notify "Task successfully completed." 'tasks/complete'
    else
        notify "Failed to complete task." 'error'
    fi
}

function modifyMenu(){
    local action=$(printf "Name\nDescription\nPriority\nDue Date\nReturn" | rofi -dmenu -p "choose one")
    local taskId=$1
        case $action in
        "Name")
            changeName $taskId
           ;;
        "Description")
            changeDescription $taskId
            ;;
        "Priority")
            changePriority $taskId
            ;;
        # "Due Date")
        #     echo "Enter new name:"
        #    ;;
        "Return")
            mainMenu
       ;;
        *)
            notify "No action selected or invalid option." 'error'
            ;;
    esac 
}

function changeName(){
  local taskId=$1
  local newName=$(rofi -dmenu -p "New Name")
  curl "https://api.todoist.com/rest/v2/tasks/$taskId" \
    -X POST \
    --data "{\"content\": \"$newName\"}" \
    -H "Content-Type: application/json" \
    -H "X-Request-Id: $(uuidgen)" \
    -H "Authorization: Bearer $TODOIST_API_KEY"
}

function changeDescription(){
  local taskId=$1
  local description=$(rofi -dmenu -p "New Description")
  curl "https://api.todoist.com/rest/v2/tasks/$taskId" \
    -X POST \
    --data "{\"description\": \"$description\"}" \
    -H "Content-Type: application/json" \
    -H "X-Request-Id: $(uuidgen)" \    
    -H "Authorization: Bearer $TODOIST_API_KEY"
}

function changePriority(){
  local taskId=$1
  local priority=$(rofi -dmenu -p "New Priority(1-4)")
  curl "https://api.todoist.com/rest/v2/tasks/$taskId" \
    -X POST \
    --data "{\"priority\": $priority}" \
    -H "Content-Type: application/json" \
    -H "X-Request-Id: $(uuidgen)" \
    -H "Authorization: Bearer $TODOIST_API_KEY"
}

function mainMenu {
    action=`printf "Add task\nView Tasks\nExit" | rofi -dmenu -i -l 2 -p 'rofi-todoist'`
    if [ "$action" = "Add task" ]; then
        addTask
		elif [ "$action" = "View Tasks" ]; then
				viewTasks
    fi

}

mainMenu