const express = require('express');
const { z } = require('zod');
const { exec } = require('child_process');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors());

function formatScriptOutput(output) {
    const lines = output.split('\n').filter(line => line.trim() !== '');

    const formatted = {
        networkConfigurations: {},
        transactionData: {},
        hashes: {}
    };

    let currentSection = null;

    for (const line of lines) {
        // Section headers
        if (line.includes('Selected Network Configurations')) {
            currentSection = 'networkConfigurations';
            continue;
        } else if (line.includes('Transaction Data and Computed Hashes')) {
            currentSection = 'transactionData';
            continue;
        } else if (line.includes('> Hashes:')) {
            currentSection = 'hashes';
            continue;
        }

        // Skip decorative lines
        if (line.startsWith('=') || line.startsWith('-')) continue;

        // Parse key-value pairs
        if (currentSection && line.includes(':')) {
            const [key, value] = line.split(':').map(part => part.trim());
            if (currentSection === 'transactionData' && key === '> Transaction Data') {
                formatted[currentSection].raw = {};
                continue;
            } else if (currentSection === 'transactionData' && key === '> Legacy Ledger Format') {
                formatted[currentSection].legacyLedgerFormat = {};
                continue;
            }

            const target =
                key.startsWith('>') && currentSection === 'transactionData'
                    ? formatted[currentSection].raw || formatted[currentSection].legacyLedgerFormat
                    : formatted[currentSection];

            // Clean up escaped characters (e.g., \u003E to >)
            const cleanedKey = key.replace(/\\u003E/g, '>');
            const cleanedValue = value.replace(/\\u003E/g, '>').replace(/\\x[0-9A-Fa-f]{2}/g, match => {
                return String.fromCharCode(parseInt(match.slice(2), 16));
            });

            target[cleanedKey] = cleanedValue;
        }
    }

    return formatted;
}

const scriptParamsSchema = z.object({
    offline: z
        .string()
        .transform(val => val === 'true' || val === '1') // Convert string to boolean
        .optional()
        .default('false'),
    data: z
        .string()
        .regex(/^0x[a-fA-F0-9]*$/, "Data must be a valid hexadecimal string starting with 0x")
        .optional(),
    address: z.string().regex(/^0x[a-fA-F0-9]{40}$/, "Invalid Ethereum address format"),
    network: z.string().min(1, "Network is required"),
    nonce: z.number().int().nonnegative("Nonce must be a non-negative integer"),
    to: z
        .string()
        .regex(/^0x[a-fA-F0-9]{40}$/, "Invalid Ethereum address format")
        .optional()
});

app.get('/safe-hashes', async (req, res) => {
    try {
        const params = scriptParamsSchema.parse({
            offline: req.query.offline,
            data: req.query.data,
            address: req.query.address,
            network: req.query.network,
            nonce: Number(req.query.nonce),
            to: req.query.to
        });


        let command = 'bash ./safe_hashes.sh';
        if (params.offline) command += ' --offline';
        if (params.data) command += ` --data ${params.data}`;
        command += ` --address ${params.address}`;
        command += ` --network ${params.network}`;
        command += ` --nonce ${params.nonce}`;
        if (params.to) command += ` --to ${params.to}`;

        exec(command, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error executing script: ${error} ${stdout} ${stderr}`);
                return res.status(500).json({
                    error: 'Script execution failed',
                    command: command,
                    killed: error.killed,
                    details: stderr
                });
            }

            const formattedOutput = stdout ? formatScriptOutput(stdout) : 'No output from script';

            res.json({
                success: true,
                output: formattedOutput,
                rawOutput: stdout,
                error: stderr || null
            });
        });

    } catch (error) {
        if (error instanceof z.ZodError) {
            return res.status(400).json({
                error: 'Validation failed',
                details: error.errors
            });
        }

        console.error(error);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
