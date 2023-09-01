// import React from 'react';

// const colorChannelMixer = (colorChannelA: number, colorChannelB: number, amountToMix: number) => {
//   let channelA = colorChannelA * amountToMix;
//   let channelB = colorChannelB * (1 - amountToMix);
//   return channelA + channelB;
// };

// const colorMixer = (rgbA: number[], rgbB: number[], amountToMix: number) => {
//   let r = colorChannelMixer(rgbA[0], rgbB[0], amountToMix);
//   let g = colorChannelMixer(rgbA[1], rgbB[1], amountToMix);
//   let b = colorChannelMixer(rgbA[2], rgbB[2], amountToMix);
//   return `rgb(${r}, ${g}, ${b})`;
// };

// const COLORS = {
//   // Colors used - https://materialui.co/flatuicolors
//   primaryColor: [231, 76, 60], // Red (Pomegranate)
//   secondColor: [39, 174, 96], // Green (Nephritis)
//   accentColor: [211, 84, 0], // Orange (Oragne)
// };

// const WeightBar: React.FC<{ percent: number; durability?: boolean }> = ({ percent, durability }) => {
//   const color = React.useMemo(
//     () =>
//       durability
//         ? percent < 50
//           ? colorMixer(COLORS.accentColor, COLORS.primaryColor, percent / 100)
//           : colorMixer(COLORS.secondColor, COLORS.accentColor, percent / 100)
//         : percent > 50
//         ? colorMixer(COLORS.primaryColor, COLORS.accentColor, percent / 100)
//         : colorMixer(COLORS.accentColor, COLORS.secondColor, percent / 50),
//     [durability, percent]
//   );

//   return (
//     <div className={durability ? 'durability-bar' : 'weight-bar'}>
//       <div
//         style={{
//           visibility: percent > 0 ? 'visible' : 'hidden',
//           height: '100%',
//           width: `${percent}%`,
//           backgroundColor: color,
//           transition: `background ${0.3}s ease, width ${0.3}s ease`,
//         }}
//       ></div>
//     </div>
//   );
// };
// export default WeightBar;


//MY WAY

import React from 'react';

const COLORS = {
  // Colors used - https://materialui.co/flatuicolors
  // primaryColor: [210,0,0], // Red (Pomegranate)
  // secondColor: [0, 210, 0], // Green (Nephritis)
  primaryColor: [150, 28, 38],
  secondColor: [255, 255, 255],
};

const colorMixer = (rgbA: number[], rgbB: number[], amountToMix: number) => {
  let r = Math.round(rgbA[0] + (rgbB[0] -rgbA[0]) * amountToMix);
  let g = Math.round(rgbA[1] + (rgbB[1] -rgbA[1]) * amountToMix);
  let b = Math.round(rgbA[2] + (rgbB[2] -rgbA[2]) * amountToMix);

  return `rgb(${r}, ${g}, ${b})`;
}

const WeightBar: React.FC<{ percent: number; durability?: boolean }> = ({ percent, durability }) => {
  const color = React.useMemo(
    () =>
      durability ? colorMixer(COLORS.primaryColor, COLORS.secondColor, percent/100) : colorMixer(COLORS.secondColor, COLORS.primaryColor, percent/100),
    [durability, percent]
  );
  return (
    <div className={durability ? 'durability-bar' : 'weight-bar'}>
      <div
        style={{
          visibility: percent > 0 ? 'visible' : 'hidden',
          height: `100%`,
          width: `${percent}%`,
          backgroundColor: color, //use backgroundmage for gradent
          transition: `background ${0.3}s ease, width ${0.3}s ease`,
        }}
      ></div>
    </div>
  );
};
export default WeightBar;
