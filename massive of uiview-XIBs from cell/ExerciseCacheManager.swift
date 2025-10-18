// Файл: ExerciseCacheManager.swift (ФИНАЛЬНАЯ ИСПРАВЛЕННАЯ ВЕРСИЯ)
import Foundation
import CoreData
import UIKit

class ExerciseCacheManager {
    static let shared = ExerciseCacheManager()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        var container: NSPersistentContainer!
        
        let initialization = {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                fatalError("Не удалось получить AppDelegate. Этого не должно было произойти.")
            }
            container = appDelegate.persistentContainer
        }
        
        if Thread.isMainThread {
            initialization()
        } else {
            DispatchQueue.main.sync {
                initialization()
            }
        }
        return container
    }()

    private init() {}
    
    func fetchCachedExercises() -> [Exercise] {
        var exercises: [Exercise] = []
        let context = persistentContainer.viewContext
        context.performAndWait {
            let request: NSFetchRequest<CachedExercise> = CachedExercise.fetchRequest()
            do {
                let cachedResults = try context.fetch(request)
                exercises = cachedResults.map { cached in
                    return Exercise(
                        id: Int(cached.id), name: cached.name ?? "", description: cached.exerciseDescription,
                        // Безопасно преобразуем сохраненный объект обратно в массив [String]
                        muscleGroup: cached.muscleGroup as? [String],
                        equipment: cached.equipment as? [String],
                        difficulty: Int(cached.difficulty), imageName: cached.imageName ?? "", videoFilename: cached.videoFilename ?? ""
                    )
                }
                print("✅ Загружено \(exercises.count) упражнений из кэша.")
            } catch {
                print("❌ Ошибка загрузки упражнений из кэша: \(error)")
            }
        }
        return exercises.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    func saveExercisesToCache(_ exercises: [Exercise]) {
        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            do {
                let deleteRequest: NSFetchRequest<NSFetchRequestResult> = CachedExercise.fetchRequest()
                let deleteBatch = NSBatchDeleteRequest(fetchRequest: deleteRequest)
                try context.execute(deleteBatch)
                
                for exercise in exercises {
                    let cachedExercise = CachedExercise(context: context)
                    cachedExercise.id = Int64(exercise.id)
                    cachedExercise.name = exercise.name
                    cachedExercise.exerciseDescription = exercise.description
                    cachedExercise.difficulty = Int16(exercise.difficulty)
                    cachedExercise.imageName = exercise.imageName
                    cachedExercise.videoFilename = exercise.videoFilename
                    
                    // --- ГЛАВНОЕ ИЗМЕНЕНИЕ: Преобразуем [String] в NSArray перед сохранением ---
                    if let muscleGroup = exercise.muscleGroup {
                        cachedExercise.muscleGroup = muscleGroup as NSArray as! [String]
                    }
                    if let equipment = exercise.equipment {
                        cachedExercise.equipment = equipment as NSArray
                    }
                    // ---------------------------------------------------------------------
                }
                
                if context.hasChanges {
                    try context.save()
                    DispatchQueue.main.async {
                        print("💾 \(exercises.count) упражнений успешно сохранено в кэш.")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ Ошибка сохранения упражнений в кэш: \(error)")
                }
                context.rollback()
            }
        }
    }
}
