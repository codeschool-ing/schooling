---
title: The catalogue
version: 1
---

This lesson recommends books, so it needs two more of Marginalia's files: the books and the
people who read them. Paste each block into the terminal, in `~/emb`, as you did with the help
centre in lesson 1.

## 60 books

`books.jsonl` is the catalogue: 60 books whose texts are in the public domain, each with its
author, year and genre, and a `blurb` of one or two sentences written for the course. **The title
and the blurb, together, are what gets embedded.**

```bash
cat > ~/emb/data/books.jsonl <<'EOF'
{"id": "b01", "title": "Pride and Prejudice", "author": "Jane Austen", "year": 1813, "genre": "romance", "blurb": "A sharp-tongued young woman and a proud rich man misjudge each other at country dances, and slowly learn better."}
{"id": "b02", "title": "Emma", "author": "Jane Austen", "year": 1815, "genre": "romance", "blurb": "A wealthy young woman who meddles in her neighbours' love lives gets every match wrong, including her own."}
{"id": "b03", "title": "Jane Eyre", "author": "Charlotte Brontë", "year": 1847, "genre": "romance", "blurb": "An orphaned governess falls for her brooding employer, whose house hides a terrible secret in the attic."}
{"id": "b04", "title": "Wuthering Heights", "author": "Emily Brontë", "year": 1847, "genre": "romance", "blurb": "A foundling and the daughter of the house share a wild love on the moors that turns to revenge across two generations."}
{"id": "b05", "title": "North and South", "author": "Elizabeth Gaskell", "year": 1855, "genre": "romance", "blurb": "A minister's daughter moves to an industrial town and clashes with a mill owner over strikes, class and pride."}
{"id": "b06", "title": "Persuasion", "author": "Jane Austen", "year": 1817, "genre": "romance", "blurb": "Eight years after she was talked out of marrying a naval officer, a woman meets him again, now rich and still hurt."}
{"id": "b07", "title": "The Hound of the Baskervilles", "author": "Arthur Conan Doyle", "year": 1902, "genre": "mystery", "blurb": "A detective investigates a legendary demon dog said to haunt a family on the lonely Devon moors."}
{"id": "b08", "title": "A Study in Scarlet", "author": "Arthur Conan Doyle", "year": 1887, "genre": "mystery", "blurb": "An army doctor shares lodgings with a strange consulting detective and helps him solve a murder in a London house."}
{"id": "b09", "title": "The Moonstone", "author": "Wilkie Collins", "year": 1868, "genre": "mystery", "blurb": "A cursed Indian diamond vanishes from a country house on the night of a birthday party, and every witness tells it differently."}
{"id": "b10", "title": "The Woman in White", "author": "Wilkie Collins", "year": 1859, "genre": "mystery", "blurb": "A drawing teacher meets a ghostly woman on a night road and uncovers a plot of stolen identity and an asylum."}
{"id": "b11", "title": "The Mysterious Affair at Styles", "author": "Agatha Christie", "year": 1920, "genre": "mystery", "blurb": "A Belgian refugee detective solves the poisoning of a rich widow in an English country manor."}
{"id": "b12", "title": "The Secret Adversary", "author": "Agatha Christie", "year": 1922, "genre": "mystery", "blurb": "Two penniless young friends start an adventure agency and stumble into a hunt for missing secret documents."}
{"id": "b13", "title": "The Time Machine", "author": "H. G. Wells", "year": 1895, "genre": "science fiction", "blurb": "A Victorian inventor travels to the year 802,701 and finds humanity split into two strange species."}
{"id": "b14", "title": "The War of the Worlds", "author": "H. G. Wells", "year": 1898, "genre": "science fiction", "blurb": "Martians land in the English countryside with heat rays and tripods, and nothing humans build can stop them."}
{"id": "b15", "title": "Frankenstein", "author": "Mary Shelley", "year": 1818, "genre": "science fiction", "blurb": "A young scientist builds a living creature from dead bodies and then abandons it, with fatal results."}
{"id": "b16", "title": "Twenty Thousand Leagues Under the Sea", "author": "Jules Verne", "year": 1870, "genre": "science fiction", "blurb": "A professor is held aboard a mysterious submarine whose captain has turned his back on the world above."}
{"id": "b17", "title": "Journey to the Centre of the Earth", "author": "Jules Verne", "year": 1864, "genre": "science fiction", "blurb": "A professor, his nephew and a guide climb down an Icelandic volcano and find a prehistoric world underground."}
{"id": "b18", "title": "The Invisible Man", "author": "H. G. Wells", "year": 1897, "genre": "science fiction", "blurb": "A scientist who has made himself invisible arrives at a village inn and slowly goes mad with power."}
{"id": "b19", "title": "Dracula", "author": "Bram Stoker", "year": 1897, "genre": "horror", "blurb": "A young lawyer visits a count's castle in Transylvania, and the count follows him to England to feed."}
{"id": "b20", "title": "The Strange Case of Dr Jekyll and Mr Hyde", "author": "Robert Louis Stevenson", "year": 1886, "genre": "horror", "blurb": "A respected London doctor drinks a potion that releases his violent other self into the night streets."}
{"id": "b21", "title": "The Turn of the Screw", "author": "Henry James", "year": 1898, "genre": "horror", "blurb": "A governess in a remote country house becomes convinced that two ghosts are after the children in her care."}
{"id": "b22", "title": "Carmilla", "author": "Sheridan Le Fanu", "year": 1872, "genre": "horror", "blurb": "A lonely girl in an Austrian castle befriends a beautiful guest who sleeps all day and grows paler each week."}
{"id": "b23", "title": "The Fall of the House of Usher", "author": "Edgar Allan Poe", "year": 1839, "genre": "horror", "blurb": "A visitor arrives at the crumbling mansion of a sick childhood friend whose sister seems to die too soon."}
{"id": "b24", "title": "The Picture of Dorian Gray", "author": "Oscar Wilde", "year": 1890, "genre": "horror", "blurb": "A beautiful young man stays young while his portrait in the attic ages and rots with every sin he commits."}
{"id": "b25", "title": "Treasure Island", "author": "Robert Louis Stevenson", "year": 1883, "genre": "adventure", "blurb": "A boy finds a pirate's map and sails with a one-legged cook who may be the most dangerous man aboard."}
{"id": "b26", "title": "The Count of Monte Cristo", "author": "Alexandre Dumas", "year": 1844, "genre": "adventure", "blurb": "A sailor wrongly imprisoned for fourteen years escapes, finds a hidden fortune and takes slow revenge on the men who betrayed him."}
{"id": "b27", "title": "The Three Musketeers", "author": "Alexandre Dumas", "year": 1844, "genre": "adventure", "blurb": "A hot-headed young man comes to Paris to join the king's guard and fights beside three swordsmen against the cardinal's spies."}
{"id": "b28", "title": "Around the World in Eighty Days", "author": "Jules Verne", "year": 1873, "genre": "adventure", "blurb": "A precise English gentleman bets his fortune that he can circle the globe by ship and train in eighty days."}
{"id": "b29", "title": "Kidnapped", "author": "Robert Louis Stevenson", "year": 1886, "genre": "adventure", "blurb": "A young Scot cheated of his inheritance is sold onto a ship and escapes across the Highlands with a rebel."}
{"id": "b30", "title": "The Call of the Wild", "author": "Jack London", "year": 1903, "genre": "adventure", "blurb": "A pet dog is stolen and sold as a sled dog in the Yukon gold rush, and learns to survive in the frozen wild."}
{"id": "b31", "title": "Moby-Dick", "author": "Herman Melville", "year": 1851, "genre": "adventure", "blurb": "A sailor joins a whaling ship whose captain will sink everything to kill the white whale that took his leg."}
{"id": "b32", "title": "Great Expectations", "author": "Charles Dickens", "year": 1861, "genre": "literary", "blurb": "A poor orphan receives money from a secret benefactor and becomes a gentleman, ashamed of where he came from."}
{"id": "b33", "title": "Middlemarch", "author": "George Eliot", "year": 1871, "genre": "literary", "blurb": "The lives of a provincial English town, its doctor, its idealistic young wife and her disastrous marriage."}
{"id": "b34", "title": "Anna Karenina", "author": "Leo Tolstoy", "year": 1878, "genre": "literary", "blurb": "A married woman in Russian high society falls in love with a cavalry officer and pays for it with everything."}
{"id": "b35", "title": "Madame Bovary", "author": "Gustave Flaubert", "year": 1857, "genre": "literary", "blurb": "A doctor's wife bored by country life chases the romance of her novels through affairs and debts."}
{"id": "b36", "title": "Crime and Punishment", "author": "Fyodor Dostoevsky", "year": 1866, "genre": "literary", "blurb": "A poor student in St Petersburg murders a pawnbroker to prove a theory, and is consumed by guilt."}
{"id": "b37", "title": "The Brothers Karamazov", "author": "Fyodor Dostoevsky", "year": 1880, "genre": "literary", "blurb": "Three brothers and their father, a murder in the family, and long arguments about God, freedom and guilt."}
{"id": "b38", "title": "Bleak House", "author": "Charles Dickens", "year": 1853, "genre": "literary", "blurb": "An endless inheritance lawsuit in London's courts ruins everyone it touches, while an orphan uncovers her mother's secret."}
{"id": "b39", "title": "Dom Casmurro", "author": "Machado de Assis", "year": 1899, "genre": "literary", "blurb": "An old man in Rio de Janeiro tells the story of his marriage and his suspicion that his wife betrayed him with his best friend."}
{"id": "b40", "title": "The Posthumous Memoirs of Brás Cubas", "author": "Machado de Assis", "year": 1881, "genre": "literary", "blurb": "A dead man narrates his idle, comfortable life in nineteenth-century Rio with ironic wit from beyond the grave."}
{"id": "b41", "title": "Alice's Adventures in Wonderland", "author": "Lewis Carroll", "year": 1865, "genre": "children", "blurb": "A girl follows a white rabbit down a hole into a world of talking animals, nonsense and a furious queen."}
{"id": "b42", "title": "The Wonderful Wizard of Oz", "author": "L. Frank Baum", "year": 1900, "genre": "children", "blurb": "A Kansas girl is carried by a cyclone to a magic land and walks a yellow road with a scarecrow, a tin man and a lion."}
{"id": "b43", "title": "Peter Pan", "author": "J. M. Barrie", "year": 1911, "genre": "children", "blurb": "A boy who will not grow up takes three children to an island of pirates, fairies and lost boys."}
{"id": "b44", "title": "The Secret Garden", "author": "Frances Hodgson Burnett", "year": 1911, "genre": "children", "blurb": "A spoiled orphan sent to a gloomy Yorkshire manor finds a locked garden and brings it, and her cousin, back to life."}
{"id": "b45", "title": "Black Beauty", "author": "Anna Sewell", "year": 1877, "genre": "children", "blurb": "A horse tells his own life story, from a happy meadow to the cruel streets of London as a cab horse."}
{"id": "b46", "title": "The Jungle Book", "author": "Rudyard Kipling", "year": 1894, "genre": "children", "blurb": "A boy raised by wolves in the Indian jungle learns its laws from a bear and a panther and faces the tiger Shere Khan."}
{"id": "b47", "title": "Walden", "author": "Henry David Thoreau", "year": 1854, "genre": "non-fiction", "blurb": "Two years living alone in a cabin by a pond, and what simple living teaches about work, money and nature."}
{"id": "b48", "title": "On the Origin of Species", "author": "Charles Darwin", "year": 1859, "genre": "non-fiction", "blurb": "The argument that species change over generations by natural selection, built from pigeons, barnacles and island birds."}
{"id": "b49", "title": "The Souls of Black Folk", "author": "W. E. B. Du Bois", "year": 1903, "genre": "non-fiction", "blurb": "Essays on race in America after emancipation, introducing the idea of double consciousness."}
{"id": "b50", "title": "A Vindication of the Rights of Woman", "author": "Mary Wollstonecraft", "year": 1792, "genre": "non-fiction", "blurb": "An argument that women are not naturally inferior to men but appear so only for lack of education."}
{"id": "b51", "title": "The Art of War", "author": "Sun Tzu", "year": -500, "genre": "non-fiction", "blurb": "An ancient Chinese treatise on strategy, deception and winning without fighting."}
{"id": "b52", "title": "Meditations", "author": "Marcus Aurelius", "year": 180, "genre": "non-fiction", "blurb": "A Roman emperor's private notes to himself on duty, death and keeping calm under pressure."}
{"id": "b53", "title": "The Adventures of Tom Sawyer", "author": "Mark Twain", "year": 1876, "genre": "adventure", "blurb": "A mischievous boy on the Mississippi witnesses a murder in a graveyard and goes looking for buried treasure."}
{"id": "b54", "title": "Little Women", "author": "Louisa May Alcott", "year": 1868, "genre": "literary", "blurb": "Four sisters grow up in New England during the Civil War, each with her own dream and her own trouble."}
{"id": "b55", "title": "The Adventures of Sherlock Holmes", "author": "Arthur Conan Doyle", "year": 1892, "genre": "mystery", "blurb": "Twelve cases for a detective who reads a stranger's life from mud on a boot and a worn sleeve."}
{"id": "b56", "title": "The Thirty-Nine Steps", "author": "John Buchan", "year": 1915, "genre": "mystery", "blurb": "A bored man in London finds a spy dead in his flat and runs across Scotland with the police and the enemy behind him."}
{"id": "b57", "title": "The Island of Doctor Moreau", "author": "H. G. Wells", "year": 1896, "genre": "science fiction", "blurb": "A shipwrecked man lands on an island where a banished scientist turns animals into creatures that walk like men."}
{"id": "b58", "title": "The Phantom of the Opera", "author": "Gaston Leroux", "year": 1910, "genre": "horror", "blurb": "A masked genius living under the Paris opera house falls for a young singer and terrorises anyone in his way."}
{"id": "b59", "title": "Sense and Sensibility", "author": "Jane Austen", "year": 1811, "genre": "romance", "blurb": "Two sisters, one cautious and one passionate, lose their home and their hopes and find love by different roads."}
{"id": "b60", "title": "The Scarlet Pimpernel", "author": "Baroness Orczy", "year": 1905, "genre": "adventure", "blurb": "An English fop is secretly the masked hero who smuggles French aristocrats away from the guillotine."}
EOF
```

## 12 readers

`readers.jsonl` says which books each of 12 readers has finished. A reader is a name and a list of
book ids, which is all a recommender built from embeddings needs to start.

```bash
cat > ~/emb/data/readers.jsonl <<'EOF'
{"reader": "r01", "name": "Bia", "finished": ["b01", "b06", "b03", "b59"]}
{"reader": "r02", "name": "Caio", "finished": ["b13", "b14", "b16"]}
{"reader": "r03", "name": "Davi", "finished": ["b07", "b55", "b11", "b09"]}
{"reader": "r04", "name": "Elisa", "finished": ["b19", "b22", "b20"]}
{"reader": "r05", "name": "Fábio", "finished": ["b25", "b26", "b31", "b29"]}
{"reader": "r06", "name": "Gabi", "finished": ["b36", "b34", "b39"]}
{"reader": "r07", "name": "Hugo", "finished": ["b41", "b43", "b42"]}
{"reader": "r08", "name": "Íris", "finished": ["b47", "b52", "b48"]}
{"reader": "r09", "name": "João", "finished": ["b07", "b19", "b15"]}
{"reader": "r10", "name": "Lia", "finished": ["b01", "b07"]}
{"reader": "r11", "name": "Marcos", "finished": []}
{"reader": "r12", "name": "Nina", "finished": ["b28"]}
EOF
```

## Checking the files

```
ana@lab:~/emb$ wc -l data/books.jsonl data/readers.jsonl
   60 data/books.jsonl
   12 data/readers.jsonl
   72 total
```

60 and 12 lines. A different number means a block went in short or twice; lesson 1's
*The help centre* says how to put it right.
