import { ItemData } from '../typings/item';

export const Items: {
  [key: string]: ItemData | undefined;
} = {
  water: {
    name: 'water',
    close: false,
    label: 'VODA',
    stack: true,
    usable: true,
    count: 0,
  },
  burger: {
    name: 'burger',
    close: false,
    label: 'BURGR',
    stack: false,
    usable: false,
    count: 0,
  },
  consumable_coffee: {
    name: 'consumable_coffee',
    close: false,
    label: 'consumable_coffee',
    stack: false,
    usable: false,
    count: 10,
  },
  lockpick: {
    name: 'lockpick',
    close: false,
    label: 'consumable_coffee',
    stack: false,
    usable: false,
    count: 10,
  },
};
