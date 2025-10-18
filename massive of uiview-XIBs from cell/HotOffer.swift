// Файл: HotOffer.swift
import Foundation

// Описывает одно "горячее предложение"
// (его название, подробное описание, фоновая картинка и текст для кнопки действия)
struct HotOffer {
    let title: String
    let description: String
    let imageName: String      // Имя картинки из Assets.xcassets
    let callToAction: String // Текст для кнопки, например "Узнать больше" или "Получить скидку"
}
