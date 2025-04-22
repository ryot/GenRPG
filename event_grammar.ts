interface Item {
    id: string;
    name: string;
    description: string;
    value?: number;
    type: ItemType;
    effect?: ItemEffect;
}

enum ItemType {
    weapon = "weapon",
    armor = "armor",
    potion = "potion",
    quest = "quest",
    treasure = "treasure",
}

interface ItemEffect {
    type: EffectType;
    value: number;
}

enum EffectType {
    healing = "healing",
    damage = "damage",
    protection = "protection",
}

interface Location {
    id: string;
    name: string;
    description: string;
    type: LocationType;
}

enum LocationType {
    room = "room",
    village = "village",
    city = "city",
    road = "road",
    shop = "shop",
    wilderness = "wilderness",
}

interface GameEvent {
    description: string;
    options: EventOption[];
}

interface EventOption {
    id: string;
    text: string;
    consequences: Consequence[];
}

interface Consequence {
    type: ConsequenceType;
    amount?: number;
    item?: Item;
    location?: Location;
}

enum ConsequenceType {
    gainXP = "gainXP",
    loseXP = "loseXP",
    gainGold = "gainGold",
    loseGold = "loseGold",
    gainItem = "gainItem",
    loseItem = "loseItem",
    changeHealth = "changeHealth",
    changeLocation = "changeLocation",
    none = "none",
}

interface Quest {
    id: string;
    name: string;
    description: string;
    isActive: boolean;
    isCompleted: boolean;
    reward: Consequence[];
}

{
    "description": "Event description.",
    "options": [
      {
        "id": "UUID",
        "text": "Option text.",
        "consequences": [
          {
            "type": "gainXP","loseXP","gainGold","loseGold","gainItem","loseItem","changeHealth","changeLocation","none",
            "amount": Int,
            "item": {
              "id": "UUID",
              "name": "Item name",
              "description: "Item description",
              "value": Int,
              "type": "weapon","armor","potion","quest","treasure",
              "effect": {
                  "type": "healing","damage","protection",
                  "value": Int
              }
            },
            "location": {
              "id": "UUID",
              "name": "Location name",
              "description": "Location description",
              "type": "room","village","city","road","shop","wilderness"
              }
          }
        ]
      }
    ]
  }