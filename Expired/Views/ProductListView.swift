//
//  ProductListView.swift
//  Expired
//
//  Created by satgi on 2023-01-25.
//

import SwiftUI
import CoreData

struct ProductListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var productStore: ProductStore
    @State private var selectedFilter: ProductFilter = .All
    @State private var showingDeleteAlert = false
    @State private var deleteIndexSet: IndexSet?
    var body: some View {
        TabView {
            // 1st Tab
            listView
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            // 2nd Tab
            SettingView()
                .tabItem {
                    Image(systemName: "gear.circle.fill")
                    Text("Settings")
                }
        }
    }
    
    @ViewBuilder
    private var listView: some View {
        NavigationView {
            List {
                Picker(selection: $selectedFilter, label: Text("Filter by status")) {
                    ForEach(ProductFilter.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                ForEach(filteredProducts) { product in
                    NavigationLink {
                        ProductEditView(product: product)
                    } label: {
                        ProductCell(product: product)
                    }
                }.onDelete(perform:showingDeleteAlert)
            }
            .listStyle(GroupedListStyle())
            .overlay(Group {
                if filteredProducts.isEmpty {
                    Text("No product found\nPress + to add your first product!")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            })
            .navigationBarTitle("Products")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProductEditView(product: nil)) {
                        Image(systemName: "plus")
                    }
                }
            }
            .popover(isPresented: $productStore.showingMemoPopover) {
                VStack {
                    Spacer()
                    Text(productStore.selectedProduct?.title ?? "")
                        .font(.title)
                    Text(productStore.selectedProduct?.memo ?? "")
                        .padding(.top, 2)
                    Spacer()
                }
                .padding()
            }
            .alert("Are you sure you want to delete this product?", isPresented: $showingDeleteAlert) {
                Button("Maybe Later", role: .cancel) {
                    deleteIndexSet = nil
                }
                Button("Yes", role: .destructive) {
                    if let indexSet = deleteIndexSet {
                        deleteProducts(indexSet: indexSet)
                    }
                    deleteIndexSet = nil
                }
            }
        }
    }

    private var filteredProducts: [Product] {
        switch selectedFilter {
            case .All:
                return productStore.products
            case .Expired, .ExpiringSoon, .Good:
                return productStore.products.filter{ filterProduct($0, selectedFilter) }
        }
    }
    
    private func deleteProducts(indexSet: IndexSet){
        withAnimation {
            indexSet.map{filteredProducts[$0]}.forEach(viewContext.delete)
            productStore.save(viewContext)
        }
    }
    
    private func showingDeleteAlert(indexSet: IndexSet) {
        // update both properties for later actions
        deleteIndexSet = indexSet
        showingDeleteAlert = true
    }

    private func filterProduct(_ product: Product, _ selectedFilter: ProductFilter) -> Bool {
        switch selectedFilter {
            case .All:
                return true
            case .Expired:
                return product.isExpired
            case .ExpiringSoon:
                return product.isExpiringSoon
            case .Good:
                return product.isGood
        }
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(ProductStore(PersistenceController.preview.container.viewContext))
    }
}
