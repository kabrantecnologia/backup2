---
name: phone-input-disabled
description: A customizable numeric input component with text alignment control and number-only input restriction
keywords: [phone, input, form, disabled, numeric, alignment, responsive]
---

#### Phone Input Component

Properties:
- `initialValue`: `string` - Initial numeric value. Default: `''`
- `disabled`: `boolean` - Controls the input's disabled state. Default: `false`
- `placeholder`: `string` - Placeholder text shown when input is empty. Default: `'Enter phone number'`
- `fontSize`: `string` - Base text size (px or rem). Default: `'1rem'`
- `textAlign`: `'left' | 'center' | 'right'` - Text alignment control. Default: `'left'`

Events:
- `change`: {value: string} - Triggered when the input value changes
- `focus`: {value: string} - Triggered when the input receives focus
- `blur`: {value: string} - Triggered when the input loses focus
- `initValueChange`: {value: string} - Triggered when the initial value changes

Special features:
- Numbers-only input restriction
- Customizable text alignment
- Disabled state with visual feedback
- Real-time input validation
- Prevents non-numeric input
- Responsive design with adaptive text sizing
- Customizable base font size with responsive scaling
- Consistent form styling across screen sizes
- Enhanced accessibility features
- High-DPI screen optimization
- Mobile-friendly input handling
- Customizable placeholder text
- Cross-browser compatibility