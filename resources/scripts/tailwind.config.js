const colors = require('tailwindcss/colors');

const gray = {
    50: 'hsl(216, 33%, 97%)',
    100: 'hsl(214, 15%, 91%)',
    200: 'hsl(210, 16%, 82%)',
    300: 'hsl(211, 13%, 65%)',
    400: 'hsl(211, 10%, 53%)',
    500: 'hsl(211, 12%, 43%)',
    600: 'hsl(209, 14%, 37%)',
    700: 'hsl(209, 18%, 30%)',
    800: 'hsl(209, 20%, 25%)',
    900: 'hsl(210, 24%, 16%)',
};

module.exports = {
    content: [
        './resources/scripts/**/*.{js,ts,tsx}',
    ],
    theme: {
        extend: {
            fontFamily: {
                header: ['"IBM Plex Sans"', '"Roboto"', 'system-ui', 'sans-serif'],
            },
            colors: {
                black: '#0a0a0a',
                // "primary" and "neutral" are deprecated, prefer the use of "blue" and "gray"
                // in new code.
                primary: colors.blue,
                gray: gray,
                neutral: gray,
                cyan: colors.cyan,
                // [neobrutalism] neon accent ramp
                lime: colors.lime,
                magenta: colors.pink,
            },
            fontSize: {
                '2xs': '0.625rem',
            },
            transitionDuration: {
                250: '250ms',
            },
            borderColor: theme => ({
                default: theme('colors.neutral.400', 'currentColor'),
            }),
            // [neobrutalism] sharp corners everywhere
            borderRadius: {
                DEFAULT: '3px',
                sm: '2px',
                md: '3px',
                lg: '5px',
                xl: '5px',
            },
            // [neobrutalism] hard offset shadows, zero blur
            boxShadow: {
                DEFAULT: '5px 5px 0 rgba(163, 230, 53, .22)',
                brutal: '5px 5px 0 #000',
                'brutal-lime': '5px 5px 0 rgba(163, 230, 53, .35)',
                'brutal-cyan': '5px 5px 0 rgba(34, 211, 238, .35)',
                'brutal-magenta': '5px 5px 0 rgba(244, 114, 182, .35)',
            },
        },
    },
    plugins: [
        require('@tailwindcss/line-clamp'),
        require('@tailwindcss/forms')({
            strategy: 'class',
        }),
    ]
};
