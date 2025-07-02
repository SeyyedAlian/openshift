Skip to content
Navigation Menu
SeyyedAlian
openshift

Type / to search
Code
Issues
Pull requests
Actions
Projects
Wiki
Security
Insights
Settings
openshift
/
Name your file...
in
main

Edit

Preview
Indent mode

Spaces
Indent size

2
Line wrap mode

No wrap
Editing file contents
Selection deleted
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
121
122
123
124
125
126
127
128
129
130
131
132
133
134
135
136
137
138
139
140
141
142
143
144
        
        # Replace image registry URLs if needed
        if [[ "$resource_type" =~ ^(deployment|deploymentconfig|statefulset|daemonset|cronjob|job)$ ]]; then
            replace_registry_urls "$final_file"
        fi
    done
}

# List of resource types to backup
RESOURCE_TYPES=(
    "deployment"
    "deploymentconfig"
    "statefulset"
    "daemonset"
    "replicaset"
    "route"
    "service"
    "ingress"
    "networkpolicy"
    "configmap"
    "secret"
    "persistentvolumeclaim"
    "storageclass"
    "serviceaccount"
    "role"
    "rolebinding"
    "imagestream"
    "buildconfig"
    "cronjob"
    "job"
)

# Backup all resource types
for resource_type in "${RESOURCE_TYPES[@]}"; do
    backup_resources "$resource_type"
done

# Backup project metadata
echo "Backing up project metadata..."
oc get project "$PROJECT_NAME" -o yaml | \
if [ "$USE_NEAT" = true ]; then kubectl-neat; else cat; fi > "$BASE_DIR/project.yaml"

# Create archive only if resources exist
if [ "$(find "$BASE_DIR" -mindepth 1 -type d | wc -l)" -gt 0 ]; then
    echo "Creating compressed archive..."
    tar -czf "${BACKUP_FOLDER}/${PROJECT_NAME}_${TIMESTAMP}.tar.gz" -C "$BACKUP_FOLDER" "${PROJECT_NAME}_${TIMESTAMP}"
    
    echo "Backup completed successfully!"
    echo "Backup location: $BASE_DIR"
    echo "Compressed archive: ${BACKUP_FOLDER}/${PROJECT_NAME}_${TIMESTAMP}.tar.gz"
else
    echo "No resources found in project $PROJECT_NAME, removing empty backup directory..."
    rm -rf "$BASE_DIR"
    exit 1
fi
Use Control + Shift + m to toggle the tab key moving focus. Alternatively, use esc then tab to move to the next interactive element on the page.
New File at / · SeyyedAlian/openshift
