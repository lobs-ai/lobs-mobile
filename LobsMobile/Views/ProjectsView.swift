import SwiftUI

struct ProjectsView: View {
    @StateObject private var viewModel = ProjectsViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.projects.isEmpty {
                    ProgressView("Loading projects...")
                } else if let error = viewModel.error, viewModel.projects.isEmpty {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task { await viewModel.loadProjects() }
                        }
                    }
                } else if viewModel.filteredProjects.isEmpty {
                    ContentUnavailableView {
                        Label("No Projects", systemImage: "folder")
                    } description: {
                        Text(viewModel.showArchived ? "No projects found." : "No active projects. Create one to get started.")
                    }
                } else {
                    projectList
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showArchived.toggle()
                    } label: {
                        Image(systemName: viewModel.showArchived ? "archivebox.fill" : "archivebox")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.resetCreateForm()
                        viewModel.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadProjects()
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                ProjectFormSheet(viewModel: viewModel)
            }
            .task {
                viewModel.setAPIService(appState.apiService)
                await viewModel.loadProjects()
            }
        }
    }
    
    private var projectList: some View {
        List {
            if !viewModel.activeProjects.isEmpty {
                Section("Active") {
                    ForEach(viewModel.activeProjects) { project in
                        NavigationLink(destination: ProjectDetailView(project: project, viewModel: viewModel)) {
                            ProjectRow(project: project)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                Task { await viewModel.archiveProject(project) }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.gray)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteProject(project) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            if viewModel.showArchived && !viewModel.archivedProjects.isEmpty {
                Section("Archived") {
                    ForEach(viewModel.archivedProjects) { project in
                        NavigationLink(destination: ProjectDetailView(project: project, viewModel: viewModel)) {
                            ProjectRow(project: project)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                Task { await viewModel.unarchiveProject(project) }
                            } label: {
                                Label("Unarchive", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(project.title)
                    .font(.headline)
                
                Spacer()
                
                ProjectTypeBadge(type: project.resolvedType)
            }
            
            if let notes = project.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Text(project.updatedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Project Type Badge

struct ProjectTypeBadge: View {
    let type: ProjectType
    
    var body: some View {
        Text(type.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }
    
    private var badgeColor: Color {
        switch type {
        case .kanban: return .blue
        case .research: return .purple
        case .tracker: return .orange
        }
    }
}

// MARK: - Project Detail

struct ProjectDetailView: View {
    let project: Project
    @ObservedObject var viewModel: ProjectsViewModel
    @State private var editedNotes: String
    @State private var isEditingNotes = false
    
    init(project: Project, viewModel: ProjectsViewModel) {
        self.project = project
        self.viewModel = viewModel
        self._editedNotes = State(initialValue: project.notes ?? "")
    }
    
    var body: some View {
        List {
            Section("Info") {
                LabeledContent("Type") {
                    ProjectTypeBadge(type: project.resolvedType)
                }
                LabeledContent("Created") {
                    Text(project.createdAt, style: .date)
                }
                LabeledContent("Updated") {
                    Text(project.updatedAt, style: .relative)
                }
                if project.archived ?? false {
                    LabeledContent("Status") {
                        Text("Archived")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Notes") {
                if isEditingNotes {
                    TextEditor(text: $editedNotes)
                        .frame(minHeight: 120)
                    
                    HStack {
                        Button("Cancel") {
                            editedNotes = project.notes ?? ""
                            isEditingNotes = false
                        }
                        Spacer()
                        Button("Save") {
                            Task {
                                await viewModel.updateNotes(project, notes: editedNotes.isEmpty ? nil : editedNotes)
                                isEditingNotes = false
                            }
                        }
                        .fontWeight(.semibold)
                    }
                } else {
                    if let notes = project.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                    } else {
                        Text("No notes")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onTapGesture {
                if !isEditingNotes {
                    isEditingNotes = true
                }
            }
            
            Section {
                if project.archived ?? false {
                    Button {
                        Task { await viewModel.unarchiveProject(project) }
                    } label: {
                        Label("Unarchive", systemImage: "arrow.uturn.backward")
                    }
                } else {
                    Button {
                        Task { await viewModel.archiveProject(project) }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                }
                
                Button(role: .destructive) {
                    Task { await viewModel.deleteProject(project) }
                } label: {
                    Label("Delete Project", systemImage: "trash")
                }
            }
        }
        .navigationTitle(project.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.prepareEdit(project)
                } label: {
                    Text("Edit")
                }
            }
        }
    }
}

// MARK: - Create/Edit Sheet

struct ProjectFormSheet: View {
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var isEditing: Bool { viewModel.editingProject != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Title", text: $viewModel.newTitle)
                    
                    Picker("Type", selection: $viewModel.newType) {
                        Text("Kanban").tag(ProjectType.kanban)
                        Text("Research").tag(ProjectType.research)
                        Text("Tracker").tag(ProjectType.tracker)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $viewModel.newNotes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Project" : "New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetCreateForm()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        Task {
                            if isEditing {
                                if let project = viewModel.editingProject {
                                    await viewModel.renameProject(project, newTitle: viewModel.newTitle)
                                    await viewModel.updateNotes(project, notes: viewModel.newNotes.isEmpty ? nil : viewModel.newNotes)
                                }
                            } else {
                                await viewModel.createProject()
                            }
                            dismiss()
                        }
                    }
                    .disabled(viewModel.newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
