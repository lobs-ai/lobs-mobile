import Foundation
import SwiftUI

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    @Published var showArchived = false
    @Published var isLoading = false
    @Published var error: String?
    
    // Create/edit sheet state
    @Published var showCreateSheet = false
    @Published var editingProject: Project?
    @Published var newTitle = ""
    @Published var newType: ProjectType = .kanban
    @Published var newNotes = ""
    
    private var apiService: APIService?
    
    func setAPIService(_ api: APIService?) {
        self.apiService = api
    }
    
    var filteredProjects: [Project] {
        projects.filter { project in
            if showArchived { return true }
            return !(project.archived ?? false)
        }
        .sorted { ($0.sortOrder ?? Int.max) < ($1.sortOrder ?? Int.max) }
    }
    
    var activeProjects: [Project] {
        filteredProjects.filter { !(($0).archived ?? false) }
    }
    
    var archivedProjects: [Project] {
        projects.filter { $0.archived ?? false }
    }
    
    func loadProjects() async {
        guard let api = apiService else {
            error = "Not connected to server"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let file = try await api.loadProjects()
            self.projects = file.projects
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createProject() async {
        guard let api = apiService else { return }
        guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        do {
            let id = newTitle.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
            let project = try await api.createProject(
                id: id,
                title: newTitle,
                type: newType,
                notes: newNotes.isEmpty ? nil : newNotes
            )
            projects.append(project)
            resetCreateForm()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func deleteProject(_ project: Project) async {
        guard let api = apiService else { return }
        
        do {
            try await api.deleteProject(id: project.id)
            projects.removeAll { $0.id == project.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func archiveProject(_ project: Project) async {
        guard let api = apiService else { return }
        
        do {
            try await api.archiveProject(id: project.id)
            if let idx = projects.firstIndex(where: { $0.id == project.id }) {
                projects[idx].archived = true
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func unarchiveProject(_ project: Project) async {
        guard let api = apiService else { return }
        
        do {
            try await api.unarchiveProject(id: project.id)
            if let idx = projects.firstIndex(where: { $0.id == project.id }) {
                projects[idx].archived = false
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func updateNotes(_ project: Project, notes: String?) async {
        guard let api = apiService else { return }
        
        do {
            try await api.updateProjectNotes(id: project.id, notes: notes)
            if let idx = projects.firstIndex(where: { $0.id == project.id }) {
                projects[idx].notes = notes
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func renameProject(_ project: Project, newTitle: String) async {
        guard let api = apiService else { return }
        
        do {
            try await api.renameProject(id: project.id, newTitle: newTitle)
            if let idx = projects.firstIndex(where: { $0.id == project.id }) {
                projects[idx].title = newTitle
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func prepareEdit(_ project: Project) {
        editingProject = project
        newTitle = project.title
        newType = project.resolvedType
        newNotes = project.notes ?? ""
        showCreateSheet = true
    }
    
    func resetCreateForm() {
        editingProject = nil
        newTitle = ""
        newType = .kanban
        newNotes = ""
        showCreateSheet = false
    }
}
