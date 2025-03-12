import { useBackend } from '../backend';
import { Button, LabeledList, Section } from '../components';
import { Window } from '../layouts';

export const BloodWriting = (props) => {
  const { act, data } = useBackend();
  const drawables = data.drawables || [];
  return (
    <Window width={600} height={600}>
      <Window.Content scrollable>
        <Section title="Stencil">
          <LabeledList>
            {drawables.map((drawable) => {
              const items = drawable.items || [];
              return (
                <LabeledList.Item key={drawable.name} label={drawable.name}>
                  {items.map((item) => (
                    <Button
                      key={item.item}
                      content={item.item}
                      selected={item.item === data.selected_stencil}
                      onClick={() =>
                        act('select_stencil', {
                          item: item.item,
                        })
                      }
                    />
                  ))}
                </LabeledList.Item>
              );
            })}
          </LabeledList>
        </Section>
        <Section title="Text">
          <LabeledList>
            <LabeledList.Item label="Current Buffer">{data.text_buffer}</LabeledList.Item>
          </LabeledList>
          <Button content="New Text" onClick={() => act('enter_text')} />
        </Section>
      </Window.Content>
    </Window>
  );
};
