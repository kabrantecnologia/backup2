<template>
    <div style="position: relative">
        <div
            ref="dropdownElement"
            @click="handleClick"
            @mouseenter="handleHoverIn"
            @mouseleave="handleHoverOut"
            @contextmenu.prevent="handleRightClick"
        >
            <wwLayout class="layout content-layout" path="triggerLayout" />
        </div>
        <div :style="style" class="dropdown" ww-responsive="dropdown">
            <div @mouseenter="handleHoverIn" @mouseleave="handleHoverOut">
                <Transition :name="this.content.animated ? 'slide' : ''">
                    <wwLayout
                        v-if="isOpened || (this.content.forceDisplayEditor && this.isEditing)"
                        path="dropdownLayout"
                    />
                </Transition>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        content: { type: Object, required: true },
        wwFrontState: { type: Object, required: true },
        wwEditorState: { type: Object, required: true },
    },
    data() {
        return {
            isOpened: false,
            coordinates: { width: 0, height: 0 },
            dropdownSize: 0,
            isMouseInside: false,
            timeoutId: 0,
            resizeObserver: null,
        };
    },
    computed: {
        isEditing() {

            // eslint-disable-next-line no-unreachable
            return false;
        },
        style() {
            const style = {};
            const { position, alignment } = this.content;
            const width = this.coordinates.width + "px";
            const height = this.coordinates.height + "px";

            const offsetX = this.content.offsetX !== undefined ? this.content.offsetX : "0px";
            const offsetY = this.content.offsetY !== undefined ? this.content.offsetY : "0px";

            const setStyles = (position) => {
                if (position === "top" || position === "bottom") {
                    style[position] = `calc(${height} + ${offsetY})`;
                } else {
                    style[position] = `calc(${width} + ${offsetX})`;
                }
            };

            setStyles(this.getOppositeSide(position));

            if (this.content.animated) {
                switch (position) {
                    case "top":
                        style["--slideOriginY"] = offsetY;
                        break;
                    case "bottom":
                        style["--slideOriginY"] = `calc(-1 * ${offsetY})`;
                        style["--slideOriginX"] = "0px";
                        break;
                    case "left":
                        style["--slideOriginX"] = offsetX;
                        style["--slideOriginY"] = "0px";
                        break;
                    case "right":
                        style["--slideOriginX"] = `calc(-1 * ${offsetX})`;
                        style["--slideOriginY"] = "0px";
                        break;
                }
            }

            switch (alignment) {
                case "start":
                    if (position === "top" || position === "bottom") {
                        if (this.content.animated) {
                            style["--transformOrigin"] = this.getOppositeSide(position) + " left";
                        }
                        style["left"] = offsetX;
                        style["--slideOriginX"] = "-" + offsetX;
                    } else {
                        if (this.content.animated) {
                            style["--transformOrigin"] = "top " + this.getOppositeSide(position);
                        }
                        style["top"] = offsetY;
                    }
                    break;
                case "center":
                    if (position === "top" || position === "bottom") {
                        if (this.content.animated) {
                            style["--transformOrigin"] = this.getOppositeSide(position) + " center";
                        }
                        style["transform"] = `translateX( calc(-50% + (${width} / 2) + ${offsetX}))`;
                        style["--slideOriginX"] = `0px`;
                    } else {
                        if (this.content.animated) {
                            style["--transformOrigin"] = "center " + this.getOppositeSide(position);
                        }
                        style["transform"] = `translateY( calc(-50% - (${height} / 2) + ${offsetY}))`;
                        // style['top'] = `0`
                        style["--slideOriginY"] = `calc(-0.5 * ((${width} / 2) + ${offsetX}))`;
                    }
                    break;
                case "end":
                    if (position === "top" || position === "bottom") {
                        if (this.content.animated) {
                            style["--transformOrigin"] = "center";
                        }
                        style["right"] = offsetX;
                        style["--slideOriginX"] = offsetX;
                    } else {
                        if (this.content.animated) {
                            style["--transformOrigin"] = "bottom " + this.getOppositeSide(position);
                        }
                        style["bottom"] = `calc(-1 * ${offsetY})`;
                    }
                    break;
            }

            style["z-index"] = this.content.dropdownZIndex || "unset";

            return style;
        },
    },
    beforeMount() {
        wwLib.getFrontDocument().addEventListener("click", this.handleClickOutside);
    },
    mounted() {
        const resizeObserver = new ResizeObserver(this.handleResize);
        const containerElement = this.$refs.dropdownElement;
        resizeObserver.observe(containerElement);
    },
    unmounted() {
        clearTimeout(this.timeoutId);
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
        }
        wwLib.getFrontDocument().removeEventListener("click", this.handleClickOutside);
    },
    methods: {
        handleClick() {
            if (
                this.content.triggerType === "click" ||
                (this.wwFrontState.screenSize !== "default" && !this.isEditing)
            ) {
                if (!this.content.disabled) this.isOpened = !this.isOpened;
            }
        },
        closeDropdown() {
            this.isOpened = false;
        },
        handleClickOutside() {
            if (
                !this.isMouseInside &&
                (this.content.triggerType === "click" ||
                    this.content.triggerType === "right-click" ||
                    this.wwFrontState.screenSize !== "default")
            ) {
                if (!this.content.disabled) this.isOpened = false;
            }
        },
        handleHoverIn() {
            if (this.content.triggerType === "hover" && this.wwFrontState.screenSize === "default" && !this.isEditing) {
                clearTimeout(this.timeoutId);
                if (!this.content.disabled) this.isOpened = true;
            } else {
                this.isMouseInside = true;
            }
        },
        handleHoverOut() {
            if (this.content.triggerType === "hover") {
                this.timeoutId = setTimeout(() => {
                    if (!this.content.disabled) this.isOpened = false;
                }, 200);
            } else {
                this.isMouseInside = false;
            }
        },
        handleRightClick() {
            if (
                this.content.triggerType === "right-click" ||
                (this.wwFrontState.screenSize !== "default" && !this.isEditing)
            ) {
                if (!this.content.disabled) this.isOpened = !this.isOpened;
            }
        },
        getOppositeSide(side) {
            const transformations = {
                top: "bottom",
                bottom: "top",
                left: "right",
                right: "left",
            };

            return transformations[side];
        },
        handleResize(entries) {
            const entry = entries[0];
            this.coordinates.width = entry.contentRect.width;
            this.coordinates.height = entry.contentRect.height;
        },
    },
};
</script>

<style lang="scss" scoped>
:root {
    --slideOriginX: 0px;
    --slideOriginY: 0px;
    --transformOrigin: top left;
}

.dropdown {
    position: absolute;
    // transform: translateX(-50%)
}

.slide-enter-active,
.slide-leave-active {
    transition: all 0.2s ease;
    transform-origin: var(--transformOrigin);
}

.slide-enter-from,
.slide-leave-to {
    opacity: 0;
    transform: translate(var(--slideOriginX), var(--slideOriginY)) scale(0.1);
}
</style>
