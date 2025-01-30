import https from 'https';
import AWS from 'aws-sdk';

const dynamoDB = new AWS.DynamoDB.DocumentClient();

export const handler = async (event) => {
  try {
    // Parse the request body
    const body = JSON.parse(event.body);
    const action = body.action;
    const leagueId = body.league;
    const date = body.date || new Date().toISOString().split('T')[0]; // Default to today
    const fromDate = body.from || null;
    const toDate = body.to || null;

    // Switch case logic for different actions
    switch (action) {
      case 'write':
        if (!leagueId || !fromDate || !toDate) {
          return {
            statusCode: 400,
            body: JSON.stringify({ error: 'Missing parameters for write action' }),
          };
        }

        // Fetch data from the API
        const apiResponse = await fetchFixturesFromAPI(leagueId, fromDate, toDate);

        // Validate API response
        if (!apiResponse || !apiResponse.response || apiResponse.response.length === 0) {
          throw new Error('API response is empty or invalid');
        }

        // Write data to DynamoDB
        await writeDataToDynamoDB(leagueId, date, apiResponse.response);

        return {
          statusCode: 200,
          body: JSON.stringify({ message: 'Fixtures cached successfully' }),
        };

      case 'read':
        if (!leagueId || !date) {
          return {
            statusCode: 400,
            body: JSON.stringify({ error: 'Missing parameters for read action' }),
          };
        }

        // Read data from DynamoDB
        const result = await readDataFromDynamoDB(leagueId, date);

        console.log('Raw DynamoDB fixtures:', JSON.stringify(result.Item.fixtures, null, 2));

        if (!result.Item) {
          return {
            statusCode: 404,
            body: JSON.stringify({ error: 'No data found for the given league and date' }),
          };
        }

        // Transform and return data
        const cleanData = transformDynamoDBData(result.Item.fixtures);
        return {
          statusCode: 200,
          body: JSON.stringify(cleanData),
        };

      default:
        return {
          statusCode: 400,
          body: JSON.stringify({ error: 'Invalid action' }),
        };
    }
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal Server Error', details: error.message }),
    };
  }
};

// Helper function to fetch data from the API
const fetchFixturesFromAPI = (leagueId, fromDate, toDate) => {
  const options = {
    method: 'GET',
    hostname: 'api-football-v1.p.rapidapi.com',
    path: `/v3/fixtures?league=${leagueId}&season=2024&from=${fromDate}&to=${toDate}`,
    headers: {
      'x-rapidapi-key': 'f5a78660bbmsh8da2d99f0a17edbp1615aejsn3221c36093ae',
      'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (error) {
          reject(new Error('Failed to parse API response'));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.end();
  });
};

// Helper function to write data to DynamoDB
const writeDataToDynamoDB = async (leagueId, date, fixtures) => {
  const params = {
    TableName: 'SportsMagicBox',
    Item: {
      league: leagueId, // Partition key
      date: date, // Sort key
      fixtures: fixtures, // The API response data
    },
  };

  console.log('Writing data to DynamoDB:', JSON.stringify(params, null, 2));
  await dynamoDB.put(params).promise();
};

// Helper function to read data from DynamoDB
const readDataFromDynamoDB = async (leagueId, date) => {
  const params = {
    TableName: 'SportsMagicBox',
    Key: { league: leagueId, date: date },
  };

  console.log('Reading data from DynamoDB with params:', JSON.stringify(params, null, 2));
  return await dynamoDB.get(params).promise();
};

// Helper function to transform DynamoDB data into clean JSON
const transformDynamoDBData = (fixtures) => {
  if (!Array.isArray(fixtures)) {
    console.error('Fixtures data is not an array:', fixtures);
    return [];
  }

  return fixtures.map((fixture, index) => {
    try {
      // Validate the required properties of each fixture
      if (
        !fixture.fixture ||
        !fixture.teams ||
        !fixture.league ||
        !fixture.score ||
        !fixture.goals
      ) {
        console.warn(`Skipping malformed fixture at index ${index}:`, fixture);
        return null;
      }

      return {
        fixture: {
          id: fixture.fixture.id || null,
          date: fixture.fixture.date || null,
          venue: {
            id: fixture.fixture.venue?.id || null,
            name: fixture.fixture.venue?.name || null,
            city: fixture.fixture.venue?.city || null,
          },
          referee: fixture.fixture.referee || null,
          status: {
            elapsed: fixture.fixture.status?.elapsed || null,
            short: fixture.fixture.status?.short || null,
            long: fixture.fixture.status?.long || null,
            extra: fixture.fixture.status?.extra || null,
          },
        },
        teams: {
          home: {
            id: fixture.teams.home?.id || null,
            name: fixture.teams.home?.name || null,
            logo: fixture.teams.home?.logo || null,
            winner: fixture.teams.home?.winner || null,
          },
          away: {
            id: fixture.teams.away?.id || null,
            name: fixture.teams.away?.name || null,
            logo: fixture.teams.away?.logo || null,
            winner: fixture.teams.away?.winner || null,
          },
        },
        league: {
          id: fixture.league.id || null,
          name: fixture.league.name || null,
          country: fixture.league.country || null,
          flag: fixture.league.flag || null,
          logo: fixture.league.logo || null,
          round: fixture.league.round || null,
        },
        goals: {
          home: fixture.goals.home || null,
          away: fixture.goals.away || null,
        },
        score: {
          halftime: {
            home: fixture.score.halftime?.home || null,
            away: fixture.score.halftime?.away || null,
          },
          fulltime: {
            home: fixture.score.fulltime?.home || null,
            away: fixture.score.fulltime?.away || null,
          },
        },
      };
    } catch (error) {
      console.error(`Error processing fixture at index ${index}:`, error, fixture);
      return null;
    }
  }).filter((fixture) => fixture !== null); // Filter out invalid items
};

