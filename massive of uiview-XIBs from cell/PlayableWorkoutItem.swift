// Файл: PlayableWorkoutItem.swift (НОВЫЙ ФАЙЛ)
import Foundation
/// Протокол, описывающий любой элемент, который может быть воспроизведен в плеере.
/// И Exercise, и Drill будут соответствовать этому протоколу.
protocol PlayableWorkoutItem {
/// Каждый элемент должен уметь преобразовывать себя в VideoItem,
/// который понимает наш плеер.
func toVideoItem() -> VideoItem?
}
