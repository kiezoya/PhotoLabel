//
//  ImagePickerView.swift
//  PhotoLabel
//
//  Created by tomworker on 2023/06/11.
//

import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    let sheetId: Int
    let sourceType: UIImagePickerController.SourceType
    @Binding var showImagePicker: Bool
    @Binding var mainCategoryIds: [MainCategoryId]
    let mainCategoryIndex: Int
    let subCategoryIndex: Int
    @Binding var workSpace: [WorkSpaceImageFile]
    @Binding var duplicateSpace: [DuplicateImageFile]
    let fileUrl: URL
    let tempDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("temp", isDirectory: true)

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMddHHmmss"
                let jpgImageData = originalImage.jpegData(compressionQuality: 0.5)
                let workSpaceImageFileName = "@\(dateFormatter.string(from: Date())).jpg"
                let workSpaceJpgUrl = parent.tempDirectoryUrl.appendingPathComponent(workSpaceImageFileName)
                let plistImageFileName = "\(dateFormatter.string(from: Date())).jpg"
                var plistJpgUrl = parent.tempDirectoryUrl.appendingPathComponent(plistImageFileName)
                let duplicateSpaceImageFileName = plistImageFileName
                do {
                    switch parent.sheetId {
                    case 1:
                        try jpgImageData!.write(to: workSpaceJpgUrl, options: .atomic)
                        parent.workSpace.insert(WorkSpaceImageFile(imageFile: workSpaceImageFileName, subDirectory: ""), at: 0)
                        ZipManager.savePlistAndZip(fileUrl: parent.fileUrl, mainCategoryIds: parent.mainCategoryIds)
                    case 2:
                        if parent.mainCategoryIds[parent.mainCategoryIndex].subFolderMode == 1 {
                            ZipManager.create(directoryUrl: parent.tempDirectoryUrl.appendingPathComponent(ZipManager.replaceString(targetString: parent.mainCategoryIds[parent.mainCategoryIndex].mainCategory)).appendingPathComponent(ZipManager.replaceString(targetString: parent.mainCategoryIds[parent.mainCategoryIndex].items[parent.subCategoryIndex].subCategory)))
                            plistJpgUrl = parent.tempDirectoryUrl.appendingPathComponent(ZipManager.replaceString(targetString: parent.mainCategoryIds[parent.mainCategoryIndex].mainCategory)).appendingPathComponent(ZipManager.replaceString(targetString: parent.mainCategoryIds[parent.mainCategoryIndex].items[parent.subCategoryIndex].subCategory)).appendingPathComponent(plistImageFileName)
                        }
                        try jpgImageData!.write(to: plistJpgUrl, options: .atomic)
                        parent.duplicateSpace.insert(DuplicateImageFile(imageFile: ImageFile(imageFile: duplicateSpaceImageFileName), subFolderMode: parent.mainCategoryIds[parent.mainCategoryIndex].subFolderMode, mainCategoryName: parent.mainCategoryIds[parent.mainCategoryIndex].mainCategory, subCategoryName: parent.mainCategoryIds[parent.mainCategoryIndex].items[parent.subCategoryIndex].subCategory), at: 0)
                        parent.mainCategoryIds[parent.mainCategoryIndex].items[parent.subCategoryIndex].images.insert(ImageFile(imageFile: plistImageFileName), at: 0)
                        parent.mainCategoryIds[parent.mainCategoryIndex].items[parent.subCategoryIndex].countStoredImages += 1
                        ZipManager.savePlistAndZip(fileUrl: parent.fileUrl, mainCategoryIds: parent.mainCategoryIds)
                    default:
                        print("SheetId have failed to be found:\(parent.sheetId)")
                    }
                } catch {
                    print("Writing Jpg file failed with error:\(error)")
                }
            }
            parent.showImagePicker.toggle()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.showImagePicker.toggle()
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIViewController(context: Context) -> some UIViewController {
        let myImagePickerController = UIImagePickerController()
        myImagePickerController.sourceType = sourceType
        myImagePickerController.delegate = context.coordinator
        return myImagePickerController
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        //none
    }
}
