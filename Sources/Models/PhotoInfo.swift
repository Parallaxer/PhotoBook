import UIKit

struct PhotoInfo {
    
    let title: String
    let detail: String
    let image: UIImage
}

extension PhotoInfo {
    
    static var defaultPhotos: [PhotoInfo] {
        return [
            PhotoInfo(
                title: "Eagle owl",
                detail: "One of the largest species of owl, with distinctive orange eyes.",
                image: UIImage(named: "owl")!
            ),
            PhotoInfo(
                title: "Tabby cat",
                detail: "Destroyer of worlds, drinker of milk.",
                image: UIImage(named: "cat-brown")!
            ),
            PhotoInfo(
                title: "Bullfinch",
                detail: "A family oriented bird, usually seen in pairs.",
                image: UIImage(named: "bullfinch")!
            ),
            PhotoInfo(
                title: "Horse",
                detail: "A majestic creature with the ability to sleep while standing.",
                image: UIImage(named: "horse")!
            ),
            PhotoInfo(
                title: "Tabby cat",
                detail: "Stalker of the unsuspecting, lover of belly rubs.",
                image: UIImage(named: "cat-silver")!
            ),

            PhotoInfo(
                title: "Eagle owl",
                detail: "One of the largest species of owl, with distinctive orange eyes.",
                image: UIImage(named: "owl")!
            ),
            PhotoInfo(
                title: "Tabby cat",
                detail: "Destroyer of worlds, drinker of milk.",
                image: UIImage(named: "cat-brown")!
            ),
            PhotoInfo(
                title: "Bullfinch",
                detail: "A family oriented bird, usually seen in pairs.",
                image: UIImage(named: "bullfinch")!
            ),
            PhotoInfo(
                title: "Horse",
                detail: "A majestic creature with the ability to sleep while standing.",
                image: UIImage(named: "horse")!
            ),
            PhotoInfo(
                title: "Tabby cat",
                detail: "Stalker of the unsuspecting, lover of belly rubs.",
                image: UIImage(named: "cat-silver")!
            )
        ]
    }
}
