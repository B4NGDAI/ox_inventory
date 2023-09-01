import React from 'react';
import { createPortal } from 'react-dom';
import { TransitionGroup } from 'react-transition-group';
import useNuiEvent from '../../hooks/useNuiEvent';
import { Fade } from '@mui/material';
import useQueue from '../../hooks/useQueue';
import { Locale } from '../../store/locale';
import { getItemUrl } from '../../helpers';
import { SlotWithItem } from '../../typings';
import { Items } from '../../store/items';
import { toInteger } from 'lodash';

interface ItemNotificationProps {
  item: SlotWithItem;
  text: string;
  count: any;
}

export const ItemNotificationsContext = React.createContext<{
  add: (item: ItemNotificationProps) => void;
} | null>(null);

export const useItemNotifications = () => {
  const itemNotificationsContext = React.useContext(ItemNotificationsContext);
  if (!itemNotificationsContext) throw new Error(`ItemNotificationsContext undefined`);
  return itemNotificationsContext;
};

const ItemNotification = React.forwardRef(
  (props: { item: ItemNotificationProps; style?: React.CSSProperties }, ref: React.ForwardedRef<HTMLDivElement>) => {
    const slotItem = props.item.item;
    const count = props.item.count;

    return (
      <div className="item-notification-wrapper" ref={ref}>
        <div className="item-notification-text-wrapper">
          <div className="item-notification-text">
            {count > 0 ? 
            <p style={{color : 'rgba(230, 10, 10,1.0)'}}>{(count.toString() + 'x - ')}</p>
            : ''
            }<p>{(slotItem.metadata?.label || Items[slotItem.name]?.label)}</p>
          </div>
          <p>{(props.item.text)}</p>
        </div>
        <div className="item-notification-item-img"
          style={{
            backgroundImage: `url(${getItemUrl(slotItem) || 'none'}`,
            ...props.style,
          }}
        >
        </div>
      </div>
    );
  }
);

export const ItemNotificationsProvider = ({ children }: { children: React.ReactNode }) => {
  const queue = useQueue<{
    id: number;
    item: ItemNotificationProps;
    ref: React.RefObject<HTMLDivElement>;
  }>();

  const add = (item: ItemNotificationProps) => {
    const ref = React.createRef<HTMLDivElement>();
    const notification = { id: Date.now(), item, ref: ref };

    queue.add(notification);

    const timeout = setTimeout(() => {
      queue.remove();
      clearTimeout(timeout);
    }, 2500);
  };

  useNuiEvent<[item: SlotWithItem, text: string, count?: number]>('itemNotify', ([item, text, count]) => {
    add({ item: item, text: `${Locale[text]}`, count: count ? toInteger(`${count}`) : 0 });
    //add({ item: item, text: `${text}`, count: count ? toInteger(`${count}`) : 0 });
  });

  return (
    <ItemNotificationsContext.Provider value={{ add }}>
      {children}
      {createPortal(
        <TransitionGroup className="item-notification-container">
          {queue.values.map((notification, index) => (
            <Fade key={`item-notification-${index}`}>
              <ItemNotification item={notification.item} ref={notification.ref} />
            </Fade>
          ))}
        </TransitionGroup>,
        document.body
      )}
    </ItemNotificationsContext.Provider>
  );
};
