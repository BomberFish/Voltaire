//
//  OnboardingInstallModelView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/4/24.
//

import MLXLMCommon
import SwiftUI

struct OnboardingInstallModelView: View {
	@EnvironmentObject var appManager: AppManager
	@State private var deviceSupportsMetal3: Bool = true
	@Binding var showOnboarding: Bool
	@State var selectedModel = ModelConfiguration.defaultModel
	let suggestedModel = ModelConfiguration.defaultModel

	func sizeBadge(_ model: ModelConfiguration?) -> String? {
		guard let size = model?.modelSize else { return nil }
        if size < 1 {
            return "\(Int(truncating: (size * 1000) as NSNumber)) MB"
        }
		return "\(size) GB"
	}

	var modelsList: some View {
		Form {
			Section {
				VStack(spacing: 12) {
					Image(systemName: "arrow.down.circle.dotted")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 64, height: 64)
						.foregroundStyle(.primary, .tertiary)
					
					VStack(spacing: 4) {
						Text("Install a model")
							.font(.title)
							.fontWeight(.semibold)
						Text("Select from models that are optimized for Apple Silicon")
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
					}
				}
				.padding(.vertical)
				.frame(maxWidth: .infinity)
			}
			.listRowBackground(Color.clear)
			
			if appManager.installedModels.count > 0 {
				Section(header: Text("Installed")) {
					ForEach(appManager.installedModels, id: \.self) { modelName in
						let model = ModelConfiguration.getModelByName(modelName)
						Button {} label: {
							Label {
								Text(appManager.modelDisplayName(modelName))
							} icon: {
								Image(systemName: "checkmark")
							}
						}
						.badge(sizeBadge(model))
#if os(macOS)
						.buttonStyle(.borderless)
#endif
						.foregroundStyle(.secondary)
						.disabled(true)
					}
				}
			} else {
				Section(header: Text("Suggested")) {
					Button { selectedModel = suggestedModel } label: {
						Label {
							Text(appManager.modelDisplayName(suggestedModel.name))
								.tint(.primary)
						} icon: {
							Image(systemName: selectedModel.name == suggestedModel.name ? "checkmark.circle.fill" : "circle")
						}
					}
					.badge(sizeBadge(suggestedModel))
#if os(macOS)
					.buttonStyle(.borderless)
#endif
				}
			}
			
			if filteredModels.count > 0 {
				Section(header: Text("Other")) {
					ForEach(filteredModels, id: \.name) { model in
						Button { selectedModel = model } label: {
							Label {
								Text(appManager.modelDisplayName(model.name))
									.tint(.primary)
							} icon: {
								Image(systemName: selectedModel.name == model.name ? "checkmark.circle.fill" : "circle")
							}
						}
						.badge(sizeBadge(model))
#if os(macOS)
						.buttonStyle(.borderless)
#endif
					}
				}
			}
		}
		.formStyle(.grouped)
	}

	var body: some View {
        VStack {
            if deviceSupportsMetal3 {
                modelsList
#if os(visionOS)
                    .listStyle(.insetGrouped)
#endif
                    .task {
                        checkModels()
                    }
#if os(iOS)
                    .safeAreaInset(edge: .bottom, alignment: .center, spacing: 8) {
                        ZStack {
                            VariableBlurView(maxBlurRadius: 8, direction: .blurredBottomClearTop)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .ignoresSafeArea(.all)
                            installButton
                                .padding(.horizontal, 12)
                                .padding(.bottom, 12)
                        }
                        .ignoresSafeArea(.all)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
#endif
#if !os(iOS) // swift, wtf?!
                Spacer()
                installButton
#endif
            } else {
                DeviceNotSupportedView()
            }
        }
		.onAppear {
			checkMetal3Support()
		}
	}
    
    var installButton: some View {
        NavigationLink(destination: OnboardingDownloadingModelProgressView(showOnboarding: $showOnboarding, selectedModel: $selectedModel)) {
            Text("Install")
#if os(iOS) || os(visionOS)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
#endif
#if os(iOS)
                .foregroundStyle(.background)
#endif
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .padding(.horizontal)
        .disabled(filteredModels.isEmpty)
    }

	var filteredModels: [ModelConfiguration] {
		ModelConfiguration.availableModels
			.filter { !appManager.installedModels.contains($0.name) }
			.filter { model in
				!(appManager.installedModels.isEmpty && model.name == suggestedModel.name)
			}
			.sorted { $0.name < $1.name }
	}

	func checkModels() {
		// automatically select the first available model
		if appManager.installedModels.contains(suggestedModel.name) {
			if let model = filteredModels.first {
				selectedModel = model
			}
		}
	}

	func checkMetal3Support() {
		#if os(iOS)
		if let device = MTLCreateSystemDefaultDevice() {
			deviceSupportsMetal3 = device.supportsFamily(.metal3)
		}
		#endif
	}
}

#Preview {
	@Previewable @State var appManager = AppManager()

	OnboardingInstallModelView(showOnboarding: .constant(true))
		.environmentObject(appManager)
}
