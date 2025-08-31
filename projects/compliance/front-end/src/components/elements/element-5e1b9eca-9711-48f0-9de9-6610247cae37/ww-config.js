export default {
editor: {
label: {
en: 'Phone Input',
},
icon: 'phone',
},
properties: {
initialValue: {
label: {
en: 'Initial value',
},
type: 'Text',
bindable: true,
section: 'settings',
defaultValue: '',
},
disabled: {
label: {
en: 'Disabled',
},
type: 'OnOff',
bindable: true,
section: 'settings',
defaultValue: false,
},
placeholder: {
label: {
en: 'Placeholder',
},
type: 'Text',
bindable: true,
section: 'settings',
defaultValue: 'Enter phone number',
},
fontSize: {
label: {
en: 'Text Size',
},
type: 'Length',
section: 'style',
bindable: true,
defaultValue: '1rem',
options: {
unitChoices: [
{ value: 'px', label: 'px', min: 8, max: 100 },
{ value: 'rem', label: 'rem', min: 0.5, max: 6 }
]
},
},
textAlign: {
label: {
en: 'Text Alignment',
},
type: 'TextRadioGroup',
section: 'style',
bindable: true,
defaultValue: 'left',
options: {
choices: [
{ value: 'left', title: 'Left', icon: 'align-left' },
{ value: 'center', title: 'Center', icon: 'align-center' },
{ value: 'right', title: 'Right', icon: 'align-right' }
]
},
}
},
triggerEvents: [
{
name: 'change',
label: { en: 'On change' },
event: { value: '' },
default: true
},
{
name: 'focus',
label: { en: 'On focus' },
event: { value: '' }
},
{
name: 'blur',
label: { en: 'On blur' },
event: { value: '' }
},
{
name: 'initValueChange',
label: { en: 'On init value change' },
event: { value: '' }
}
]
};