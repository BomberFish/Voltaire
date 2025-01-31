//
//  Models.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/4/24.
//

import MLXLMCommon
import Foundation

public extension ModelConfiguration {
    enum ModelType {
        case regular, reasoning
    }
    
    var modelType: ModelType {
        switch self {
        case .deepseek_r1_distill_qwen_1_5b_4bit,.deepseek_r1_distill_llama_8b_4bit: .reasoning
        default: .regular
        }
    }
}

extension ModelConfiguration: @retroactive Equatable {
    public static func == (lhs: MLXLMCommon.ModelConfiguration, rhs: MLXLMCommon.ModelConfiguration) -> Bool {
        return lhs.name == rhs.name
    }
    
    public static let deepseek_r1_distill_qwen_1_5b_4bit = ModelConfiguration(
        id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-4bit"
    )
    
    public static let deepseek_r1_distill_llama_8b_4bit = ModelConfiguration(
        id: "mlx-community/DeepSeek-R1-Distill-Llama-8B-4bit"
    )
    
    public static let llama_3_2_1b_4bit = ModelConfiguration(
        id: "mlx-community/Llama-3.2-1B-Instruct-4bit"
    )
    
    public static let llama_3_2_3b_4bit = ModelConfiguration(
        id: "mlx-community/Llama-3.2-3B-Instruct-4bit"
    )
    
    public static let gemma_2_2b_it_4bit = ModelConfiguration(
        id: "mlx-community/gemma-2-2b-it-4bit"
    )
    
    public static let phi_3_5_mini_instruct_4bit = ModelConfiguration(
        id: "mlx-community/Phi-3.5-mini-instruct-4bit"
    )
    
    public static let qwen2_5_1_5b_instruct_4bit = ModelConfiguration(
        id: "mlx-community/Qwen2.5-1.5B-Instruct-4bit"
    )
    
    public static let falcon3_3b_instruct_3bit = ModelConfiguration(
        id: "mlx-community/Falcon3-3B-Instruct-3bit"
    )
    
    public static let openelm_1_1b_instruct_4bit = ModelConfiguration(
        id: "mlx-community/OpenELM-1_1B-Instruct-4bit"
    )
    
    public static let openelm_1_1b_instruct_8bit = ModelConfiguration(
        id: "mlx-community/OpenELM-1_1B-Instruct-8bit"
    )
    
    #if os(iOS)
    public static var availableModels: [ModelConfiguration] = [
        deepseek_r1_distill_qwen_1_5b_4bit,
        llama_3_2_1b_4bit,
        llama_3_2_3b_4bit,
        phi_3_5_mini_instruct_4bit,
        qwen2_5_1_5b_instruct_4bit,
        falcon3_3b_instruct_3bit,
        gemma_2_2b_it_4bit,
//        openelm_1_1b_instruct_4bit,
//        openelm_1_1b_instruct_8bit,
    ]
    #else
    public static var availableModels: [ModelConfiguration] = [
        deepseek_r1_distill_llama_8b_4bit,
        deepseek_r1_distill_qwen_1_5b_4bit,
        llama_3_2_1b_4bit,
        llama_3_2_3b_4bit,
        phi_3_5_mini_instruct_4bit,
        qwen2_5_1_5b_instruct_4bit,
        gemma_2_2b_it_4bit,
        falcon3_3b_instruct_3bit,
//        openelm_1_1b_instruct_4bit,
//        openelm_1_1b_instruct_8bit,
    ]
    #endif
    
    public static var defaultModel: ModelConfiguration {
        #if os(iOS)
        deepseek_r1_distill_qwen_1_5b_4bit
        #else
        deepseek_r1_distill_llama_8b_4bit
        #endif
    }
    
    public static func getModelByName(_ name: String) -> ModelConfiguration? {
        if let model = availableModels.first(where: { $0.name == name }) {
            return model
        } else {
            return nil
        }
    }
    
    func getPromptHistory(thread: Thread, systemPrompt: String) -> [[String: String]] {
        var history: [[String: String]] = []
        
        // system prompt
        history.append([
            "role": "system",
            "content": systemPrompt
        ])
        
        // messages
        for message in thread.sortedMessages {
            let role = message.role.rawValue
            history.append([
                "role": role,
                "content": message.content
            ])
        }
        
        return history
    }
    
    /// Returns the model's approximate size, in GB.
    public var modelSize: Decimal? {
        switch self {
        case .deepseek_r1_distill_qwen_1_5b_4bit: 1
        case .deepseek_r1_distill_llama_8b_4bit: 4.5
        case .llama_3_2_1b_4bit: 0.695
        case .llama_3_2_3b_4bit: 1.8
        case .gemma_2_2b_it_4bit: 1.5
        case .falcon3_3b_instruct_3bit: 1.8
        case .phi_3_5_mini_instruct_4bit: 2.15
        case .qwen2_5_1_5b_instruct_4bit: 0.87
        case .openelm_1_1b_instruct_4bit: 0.608
        case .openelm_1_1b_instruct_8bit: 1.15
        default: nil
        }
    }
    
    public var familyName: String {
        switch self {
        case .deepseek_r1_distill_qwen_1_5b_4bit, .deepseek_r1_distill_llama_8b_4bit: "DeepSeek R1"
        case .llama_3_2_1b_4bit,.llama_3_2_3b_4bit: "LLaMa 3.2"
        case .gemma_2_2b_it_4bit: "Gemma 2"
        case .falcon3_3b_instruct_3bit: "Falcon 3"
        case .phi_3_5_mini_instruct_4bit: "Phi 3.5"
        case .qwen2_5_1_5b_instruct_4bit: "Qwen 2.5"
        case .openelm_1_1b_instruct_4bit, .openelm_1_1b_instruct_8bit: "OpenELM"
        default: self.name.replacing("mlx-community/", with: "").components(separatedBy: "-")[0].capitalized
        }
    }
}
