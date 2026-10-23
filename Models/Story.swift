import Foundation

/// Moral and inspirational stories for VoCo Gyan matching storytelling2.dart
public struct Story: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let narrativeText: String
    public let moral: String

    public init(id: String, title: String, narrativeText: String, moral: String) {
        self.id = id
        self.title = title
        self.narrativeText = narrativeText
        self.moral = moral
    }
}

extension Story {
    public static let standardStories: [Story] = [
        Story(
            id: "story-1",
            title: "The Potato, The Egg, And The Coffee Beans",
            narrativeText: """
            Once upon a time, a daughter complained to her father that her life was miserable and that she didn’t know how she was going to make it. She was tired of fighting and struggling all the time. It seemed just as one problem was solved, another one soon followed.

            Her father, a chef, took her to the kitchen. He filled three pots with water and placed each on a high fire. Once the three pots began to boil, he placed potatoes in one pot, eggs in the second pot, and ground coffee beans in the third pot.

            He then let them sit and boil, without saying a word to his daughter. The daughter, moaned and impatiently waited, wondering what he was doing. After twenty minutes he turned off the burners. He took the potatoes out of the pot and placed them in a bowl. He pulled the eggs out and placed them in a bowl. He then ladled the coffee out and placed it in a cup.

            Turning to her he asked. "Daughter, what do you see?"
            "Potatoes, eggs, and coffee," she hastily replied.
            "Look closer," he said, "and touch the potatoes." She did and noted that they were soft. He then asked her to take an egg and break it. After pulling off the shell, she observed the hard-boiled egg. Finally, he asked her to sip the coffee. Its rich aroma brought a smile to her face.

            "Father, what does this mean?" she asked.
            He then explained that the potatoes, the eggs and coffee beans had each faced the same adversity– the boiling water. However, each one reacted differently. The potato went in strong, hard, and unrelenting, but in boiling water, it became soft and weak. The egg was fragile, with the thin outer shell protecting its liquid interior until it was put in the boiling water. Then the inside of the egg became hard. However, the ground coffee beans were unique. After they were exposed to the boiling water, they changed the water and created something new.

            "Which are you?" he asked his daughter. "When adversity knocks on your door, how do you respond? Are you a potato, an egg, or a coffee bean?"
            """,
            moral: "In life, things happen around us, things happen to us, but the only thing that truly matters is how you choose to react to it and what you make out of it. Life is all about leaning, adopting and converting all the struggles that we experience into something positive."
        ),
        Story(
            id: "story-2",
            title: "The Dishonest Merchant",
            narrativeText: """
            Once upon a time, there lived a merchant named Mohan in a bustling riverside town. He was notorious for deceiving his customers by manipulating his weighing scales. Whenever someone bought grain, his scales showed more weight than the actual amount.

            One summer, a devastating flood threatened the town. Mohan hurried to load all his gold and silver onto a boat to flee downriver. However, because he had also secretly overloaded the vessel with heavy lead weights used to cheat his patrons, the boat became unstable in the turbulent currents.

            As the boat began taking on water, Mohan realized he had to discard the heavy weights to save his vessel. But his greed made him hesitate. By the time he threw the weights overboard, the hull had ruptured, and all his treasures sank to the riverbed. Mohan barely swam ashore with nothing left.
            """,
            moral: "Dishonesty and deceit ultimately bring ruin upon those who practice them. Honesty and integrity are life’s true ballast."
        ),
        Story(
            id: "story-3",
            title: "The Clever Fox and the Crow",
            narrativeText: """
            A crow was sitting on a branch of a tree with a piece of cheese in her beak. A fox, wandering through the woods, caught scent of the delicious treat and stopped beneath the branch.

            Looking up, the fox began showering the crow with praises: "Good day, beautiful bird! How glossy your feathers are, and how bright your eyes shine! Surely a bird of such beauty must possess the sweetest voice in the entire forest. Will you not sing a song for me?"

            The flattered crow, puffed up with pride, opened her beak to let out a loud caw. The moment her beak opened, the morsel of cheese fell directly into the waiting jaws of the fox, who snapped it up and laughed.
            """,
            moral: "Do not let false flattery cloud your judgment and common sense."
        ),
        Story(
            id: "story-4",
            title: "The Ant and the Grasshopper",
            narrativeText: """
            On a bright summer day, a grasshopper was hopping and chirping merrily across the meadow. An ant passed by, bearing along with great effort an ear of corn he was taking to the nest.

            "Why not come and chat with me," said the grasshopper, "instead of toiling and moiling in that way?"
            "I am helping to lay up food for the winter," replied the ant, "and recommend you to do the same."
            "Why bother about winter?" said the grasshopper; "we have plenty of food at present." But the ant went on its way and continued its toil.

            When winter came, the grasshopper had no food and found itself dying of hunger, while it saw the ants distributing every day corn and grain from the stores they had collected in the summer.
            """,
            moral: "There is a time for work and a time for play. Diligent preparation today secures peace tomorrow."
        )
    ]
}
