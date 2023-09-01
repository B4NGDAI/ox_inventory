import { Box } from '@mui/material';
import InventoryComponent from './components/inventory';
import useNuiEvent from './hooks/useNuiEvent';
import { Items } from './store/items';
import { Locale } from './store/locale';
import { setImagePath } from './store/imagepath';
import { setupInventory } from './store/inventory';
import { Inventory } from './typings';
import { useAppDispatch } from './store';
import { debugData } from './utils/debugData';
import DragPreview from './components/utils/DragPreview';
import { fetchNui } from './utils/fetchNui';
import { useDragDropManager } from 'react-dnd';
import KeyPress from './components/utils/KeyPress';

debugData([
  {
    action: 'setupInventory',
    data: {
      leftInventory: {
        id: 'test',
        type: 'player',
        slots: 50,
        label: 'Bob Smith',
        weight: 3000,
        maxWeight: 5000,
        items: [
          {
            slot: 1,
            name: 'character_role_token',
            weight: 2000,
            metadata: {
              description: `name: Svetozar Miletic  \n Gender: Male`,
              ammo: 3,
              mustard: '60%',
              ketchup: '30%',
              mayo: '10%',
              durability: 100,
              serial: '12345',
              components: {
                '1' : 'Test 1',
                '2' : 'Test 2'
              }
            },
            count: 5,
          },
          { slot: 2, name: 'consumable_apple', weight: 0, count: 1, metadata: { durability: 75 } },
          { slot: 3, name: 'consumable_coffee', weight: 100, count: 1200, metadata: { durability: 50 } },
          {
            slot: 4,
            name: 'consumable_gin',
            weight: 0,
            count: 1,
            metadata: { description: 'Generic item description', durability: 25 },
          },
          { slot: 5, name: 'consumable_peach', weight: 0, count: 1, metadata: {
            label: 'Russian Cream',
            durability: 10,
          } },
          { slot:6, name: 'consumable_peach', weight: 0, count: 1, metadata: {
            label: 'Russian Cream',
            durability: 0,
          }},
        ],
      },
      rightInventory: {
        id: 'craft',
        type: 'crafting',
        slots: 50,
        label: 'Bob Smith',
        weight: 3000,
        maxWeight: 5000,
        items: [
          {
            slot: 1,
            name: 'lockpick',
            weight: 1000,
            price: 300,
            ingredients: {
              consumable_coffee: 1,
            },
            duration: 10,
            metadata: {
              description: 'Simple lockpick that breaks easily and can pick basic door locks',
              serial: '12345',
              //durability: 50,
              imageurl: "https://i.imgur.com/2xHhTTz.png"
            },
          },
        ],
      },
    },
  },
]);
// debugData([
//   {
//     action: 'itemNotify',
//     data: [
//       {
//         name: 'AMMO_ARROW',
//         count: 5,
//         weight: 4500,
//         metadata: {
//           label: 'Pistol Ammo',
//           ammo: 3,
//           mustard: '60%',
//           ketchup: '30%',
//           mayo: '10%',
//           durability: 100,
//         },
//       },
//       'Removed',
//       10
//     ],
//   },
//     {
//     action: 'itemNotify',
//     data: [
//       {
//         name: 'WEAPON_REVOLVER_CATTLEMAN',
//         count: 5,
//         weight: 4500,
//         metadata: {
//           label: 'Revolver - Cattleman',
//           ammo: 3,
//           mustard: '60%',
//           ketchup: '30%',
//           mayo: '10%',
//           durability: 100,
//         },
//       },
//       'Holstered',
//       //10
//     ],
//   }

// ]);

const App: React.FC = () => {
  const dispatch = useAppDispatch();
  const manager = useDragDropManager();

  useNuiEvent<{
    locale: { [key: string]: string };
    items: typeof Items;
    leftInventory: Inventory;
    imagepath: string;
  }>('init', ({ locale, items, leftInventory, imagepath }) => {
    for (const name in locale) Locale[name] = locale[name];
    for (const name in items) Items[name] = items[name];

    setImagePath(imagepath);
    dispatch(setupInventory({ leftInventory }));
  });

  fetchNui('uiLoaded', {});

  useNuiEvent('closeInventory', () => {
    manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  return (
    <Box sx={{ height: '100%', width: '100%', color: 'white' }}>
      <InventoryComponent />
      <DragPreview />
      <KeyPress />
    </Box>
  );
};

export default App;
