<template>
<div class="phone-input-container">
<input
type="tel"
inputmode="numeric"
pattern="[0-9]*"
class="phone-input"
:class="{ 'phone-input--disabled': content.disabled }"
:value="formattedValue"
:placeholder="content.placeholder"
:disabled="content.disabled"
:style="inputStyle"
@input="handleInput"
@focus="handleFocus"
@blur="handleBlur"
/>
</div>
</template>

<script>
import { computed, ref, watch } from 'vue';

export default {
props: {
content: { type: Object, required: true },
uid: { type: String, required: true },
},
emits: ['trigger-event'],
setup(props, { emit }) {
const { value: internalValue, setValue: setInternalValue } = wwLib.wwVariable.useComponentVariable({
uid: props.uid,
name: 'value',
defaultValue: computed(() => props.content.initialValue || ''),
});

const formatPhoneNumber = (value) => {
const numbers = value.replace(/\D/g, '').substring(0, 10);
if (numbers.length === 0) return '';
if (numbers.length <= 3) return numbers;
if (numbers.length <= 6) return `${numbers.slice(0, 3)}-${numbers.slice(3)}`;
return `${numbers.slice(0, 3)}-${numbers.slice(3, 6)}-${numbers.slice(6)}`;
};

const formattedValue = computed(() => formatPhoneNumber(internalValue.value || ''));

const inputStyle = computed(() => ({
fontSize: props.content?.fontSize || '1rem',
textAlign: props.content?.textAlign || 'left',
width: '100%'
}));

watch(() => props.content.initialValue, (newValue) => {
if (newValue !== undefined && newValue !== internalValue.value) {
setInternalValue(newValue);
emit('trigger-event', {
name: 'initValueChange',
event: { value: newValue }
});
}
});

const handleInput = (event) => {
if (props.content.disabled) return;

const numericValue = event.target.value.replace(/\D/g, '');
setInternalValue(numericValue);
emit('trigger-event', {
name: 'change',
event: { value: numericValue }
});
};

const handleFocus = () => {
if (!props.content.disabled) {
emit('trigger-event', {
name: 'focus',
event: { value: internalValue.value }
});
}
};

const handleBlur = () => {
if (!props.content.disabled) {
emit('trigger-event', {
name: 'blur',
event: { value: internalValue.value }
});
}
};

return {
formattedValue,
handleInput,
handleFocus,
handleBlur,
inputStyle
};
},
};
</script>

<style lang="scss" scoped>
.phone-input-container {
width: 100%;
}

.phone-input {
width: 100%;
margin: 0;
padding: 0;
border: none;
outline: none;
background: transparent;
font-family: inherit;

&--disabled {
opacity: 0.7;
cursor: not-allowed;
}

/* Prevent iOS zoom on focus */
@media screen and (max-width: 768px) {
font-size: max(16px, 1rem);
}
}
</style>