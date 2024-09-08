//
//  IngredientsCheckView.swift
//  ShineUp
//
//  Created by Swarasai Mulagari on 9/7/24.
//

import SwiftUI
import Vision

struct IngredientsCheckView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var ingredientsAnalysis: String = ""
    @State private var showTextAndButton: Bool = true
    @State private var analysisCompleted: Bool = false
    
    let extractedText: String
    let skinCondition: String
    
    var body: some View {
        VStack {
            if showTextAndButton {
                Spacer()
                
                VStack {
                    Text("Ingredients Check")
                        .font(.custom("AvenirNext-Bold", size: 36))
                        .padding()
                    
                    ScrollView {
                        Text(extractedText)
                            .padding()
                    }
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Text("Analyze Ingredients")
                            .font(.custom("AvenirNext-Bold", size: 20))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(sourceType: .camera, selectedImage: $selectedImage) { image in
                            analyzeImage(image: image)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                
                Spacer()
            } else {
                VStack {
                    Spacer()
                    
                    Text(ingredientsAnalysis)
                        .font(.custom("AvenirNext-Bold", size: 20))
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
        }
        .padding()
        .onAppear {
            if analysisCompleted {
                // Reset the state when view appears if analysis was completed
                showTextAndButton = false
                analysisCompleted = false
            }
        }
    }
    
    private func analyzeImage(image: UIImage?) {
        guard let image = image else {
            ingredientsAnalysis = "Failed to capture image."
            return
        }
        
        extractText(from: image) { extractedText in
            let (result, goodIngredientsList, badIngredientsList) = evaluateIngredients(text: extractedText)
            DispatchQueue.main.async {
                var resultText = result
                if !goodIngredientsList.isEmpty {
                    resultText += "\n\nGood Ingredients: \(goodIngredientsList)"
                }
                if !badIngredientsList.isEmpty {
                    resultText += "\n\nBad Ingredients: \(badIngredientsList)"
                }
                ingredientsAnalysis = resultText
                showTextAndButton = false
                analysisCompleted = true // Mark analysis as completed
            }
        }
    }
    
    private func extractText(from image: UIImage, completion: @escaping (String) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Error recognizing text: \(error)")
                completion("")
                return
            }
            
            let observations = request.results as? [VNRecognizedTextObservation]
            let recognizedStrings = observations?.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let fullText = recognizedStrings?.joined(separator: "\n") ?? ""
            completion(fullText)
        }
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform text recognition request: \(error)")
                completion("")
            }
        }
    }
    
    private func evaluateIngredients(text: String) -> (String, String, String) {
        // Define good and bad ingredients for each skin condition
        let conditionBasedRecommendations: [String: (good: [String], bad: [String])] = [
            "acne": (good: ["Beans", "Oats", "Omega-3 Fatty Acids"], bad: ["Milk", "Sugar", "Grains"]),
            "carcinoma": (good: ["Oats", "Pasta", "Walnut", "Avocado"], bad: ["Unpasteurized Juice", "Raw Shellfish", "Milk", "Eggs", "Yogurt", "Chicken", "Rice"]),
            "eczema": (good: ["Oranges", "Bananas", "Beets", "Fish"], bad: ["Milk", "Eggs", "Wheat", "Soy", "Peanuts", "Tree Nuts", "Shellfish"]),
            "keratosis": (good: ["Sardines", "Mackerel", "Salmon"], bad: ["Milk", "Cheese", "Red Meat", "Soy", "Peanuts"]),
            "milia": (good: ["Beans", "Oats", "Omega-3 Fatty Acids"], bad: ["Milk", "Sugar", "Grains"]),
            "rosacea": (good: ["Oats", "Brown Rice", "Quinoa"], bad: ["Oranges", "Alcohol", "Chocolate", "Cinnamon", "Tomatoes", "Cheese", "Nuts"])
        ]
        
        guard let recommendations = conditionBasedRecommendations[skinCondition.lowercased()] else {
            return ("Unknown skin condition.", "", "")
        }
        
        let goodIngredients = recommendations.good
        let badIngredients = recommendations.bad
        
        // Check if the text contains any good or bad ingredients
        let goodIngredientsList = goodIngredients.filter { text.contains($0) }.joined(separator: ", ")
        let badIngredientsList = badIngredients.filter { text.contains($0) }.joined(separator: ", ")
        
        if !badIngredientsList.isEmpty {
            return ("The product contains ingredients that are not recommended for your condition.", goodIngredientsList, badIngredientsList)
        } else if !goodIngredientsList.isEmpty {
            return ("The product contains ingredients that are beneficial for your condition.", goodIngredientsList, "")
        } else {
            return ("The product's ingredients do not have a specific recommendation for your condition.", "", "")
        }
    }
}

struct IngredientsCheckView_Previews: PreviewProvider {
    static var previews: some View {
        IngredientsCheckView(extractedText: "Sample extracted text from image.", skinCondition: "acne")
    }
}
