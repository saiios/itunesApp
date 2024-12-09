import SwiftUI
import Combine

struct MediaResponse: Codable {
    let results: [MediaItem]
}

struct MediaItem: Codable, Identifiable {
    let id = UUID()
    let trackName: String?
    let artistName: String?
    let kind: String?
    let artworkUrl100: String?
    let previewUrl: String?

    var title: String {
        trackName ?? "Unknown Title"
    }
    var artist: String {
        artistName ?? "Unknown Artist"
    }
    var mediaType: String {
        kind ?? "Unknown Media"
    }
    var artworkURL: URL? {
        if let urlString = artworkUrl100 {
            return URL(string: urlString)
        }
        return nil
    }
    var previewURL: URL? {
        if let urlString = previewUrl {
            return URL(string: urlString)
        }
        return nil
    }
}

// ViewModel
class iTunesViewModel: ObservableObject {
    @Published var searchTerm: String = ""
    @Published var results: [MediaItem] = []

    private var cancellables = Set<AnyCancellable>()

    func searchMedia() {
        guard let searchTermEncoded = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(searchTermEncoded)&media=all") else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MediaResponse.self, decoder: JSONDecoder())
            .map(\.results)
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$results)
    }
}

// Main View
struct iTunesSearchView: View {
    @StateObject private var viewModel = iTunesViewModel()

    var body: some View {
        VStack {
            TextField("Search", text: $viewModel.searchTerm, onCommit: {
                viewModel.searchMedia()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

            List(viewModel.results) { item in
                HStack {
                    AsyncImage(url: item.artworkURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(item.title).font(.headline)
                        Text(item.artist).font(.subheadline)
                    }
                }
            }
        }
    }
}
